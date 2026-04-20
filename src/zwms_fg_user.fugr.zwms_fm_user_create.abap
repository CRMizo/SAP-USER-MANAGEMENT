FUNCTION zwms_fm_user_create.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_USER_ID) TYPE  ZWMS_USER_ID
*"     VALUE(IV_USER_NAME) TYPE  ZWMS_USER_NAME
*"     VALUE(IV_PASSWORD) TYPE  XUNCODE
*"     VALUE(IV_REQUEST_ID) TYPE  ZWMS_USER_ID
*"     VALUE(IS_ADDICTIONAL) TYPE  ZWMS_S_USER_PROPERTIES OPTIONAL
*"  EXPORTING
*"     VALUE(EV_TYPE) TYPE  BAPI_MTYPE
*"     VALUE(EV_MSG) TYPE  BAPI_MSG
*"  EXCEPTIONS
*"      FAILED_TO_GENERATE_SALT
*"----------------------------------------------------------------------
  IF iv_user_id IS INITIAL.
    ev_type = 'E'.
    ev_msg  = 'User ID cannot be empty.'.
    RETURN.
  ENDIF.

  IF iv_password IS INITIAL.
    ev_type = 'E'.
    ev_msg  = 'Password cannot be empty.'.
    RETURN.
  ENDIF.

  iv_user_id = to_upper( iv_user_id ).

  " Check if the user id already exists
  SELECT SINGLE @abap_true FROM zwms_t_user
    WHERE user_id = @iv_user_id
    INTO @DATA(lv_user_exists).
  IF lv_user_exists = abap_true.
    ev_type = 'E'.
    ev_msg  = 'User ID already exists.'.
    RETURN.
  ENDIF.

  DATA lv_pwd_check_msg TYPE string.
  DATA ls_bapipwd       TYPE bapipwd.
  ls_bapipwd-bapipwd = iv_password.
  CALL FUNCTION 'PASSWORD_FORMAL_CHECK'
    EXPORTING  password        = ls_bapipwd
               security_policy = 'ZPASSWORD_POLICY_01'
    IMPORTING  msgtext         = lv_pwd_check_msg
    EXCEPTIONS internal_error  = 1
               OTHERS          = 2.
  IF sy-subrc <> 0.
    ev_type = 'E'.
    ev_msg = lv_pwd_check_msg.
    RETURN.
  ENDIF.

  " Generate the Salt UUID
  TRY.
      DATA(lv_salt) = cl_system_uuid=>create_uuid_c32_static( ).
    CATCH cx_uuid_error INTO DATA(lx_uuid).
      RAISE failed_to_generate_salt.
      ev_type = 'E'.
      ev_msg  = |Failed to generate the Salt:{ lx_uuid->get_text( ) }|.
      RETURN.
  ENDTRY.

  " Concatenating the Password and Salt
  DATA(lv_salted_pwd) = iv_password && lv_salt.
  DATA lv_pwd_hash TYPE string.

  TRY.
      cl_abap_message_digest=>calculate_hash_for_char( EXPORTING if_algorithm  = 'SHA512'
                                                                 if_data       = lv_salted_pwd
                                                       IMPORTING ef_hashstring = lv_pwd_hash ).
    CATCH cx_abap_message_digest INTO DATA(lx_digest).
      ev_type = 'E'.
      ev_msg = |Failed to calculate Hash:{ lx_digest->get_text( ) }|.
      RETURN.
  ENDTRY.

  DATA ls_new_user TYPE zwms_t_user.

  ls_new_user = VALUE #( user_id       = iv_user_id
                         user_name     = iv_user_name
                         pwd_initial   = abap_true
                         creation_date = sy-datum
                         creation_user = iv_request_id
                         pwd_salt      = lv_salt
                         pwd_hash      = lv_pwd_hash
                         email         = is_addictional-email
                         gender        = is_addictional-gender
                         phone         = is_addictional-phone
                         administrator = is_addictional-administrator ).

  INSERT zwms_t_user FROM ls_new_user.
  IF sy-subrc = 0.
    ev_type = 'S'.
    ev_msg = |User  { iv_user_id } created successfully.|.
  ELSE.
    ev_type = 'E'.
    ev_msg = |Datebase insert failed.|.
  ENDIF.
ENDFUNCTION.
