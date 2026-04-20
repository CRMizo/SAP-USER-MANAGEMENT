FUNCTION zwms_fm_user_change_pwd.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_USER_ID) TYPE  ZWMS_USER_ID
*"     VALUE(IV_OLD_PASSWORD) TYPE  XUNCODE OPTIONAL
*"     VALUE(IV_NEW_PASSWORD) TYPE  XUNCODE
*"     VALUE(IV_REQUEST_ID) TYPE  ZWMS_USER_ID
*"  EXPORTING
*"     VALUE(EV_TYPE) TYPE  BAPI_MTYPE
*"     VALUE(EV_MSG) TYPE  BAPI_MSG
*"----------------------------------------------------------------------

  IF iv_user_id IS INITIAL
  OR iv_new_password IS INITIAL.
    ev_type = 'E'.
    ev_msg  = 'User ID, Old Password, and New Password cannot be empty.'.
    RETURN.
  ENDIF.

  DATA(lv_user_id) = to_upper( iv_user_id ).

  " Check if SAP Standard Account
  SELECT SINGLE
         @abap_true
    FROM usr02
    WHERE bname = @lv_user_id
    INTO @DATA(lv_is_sap_account).
  IF lv_is_sap_account = abap_true.
    ev_type = 'E'.
    ev_msg  = |{ lv_is_sap_account } is a SAP Standard account, cannot be changed via WMS. Please use SAP.|.
    RETURN.
  ENDIF.


  " Get WMS user info
  SELECT SINGLE
         pwd_salt,
         pwd_hash
    FROM zwms_t_user
    WHERE user_id = @lv_user_id
    INTO @DATA(ls_wms_pwd).
  IF sy-subrc <> 0.
    ev_type = 'E'.
    ev_msg  = 'User ID does not exist.'.
    RETURN.
  ENDIF.

  " Check If the Request User is an administrator
  SELECT SINGLE
         @abap_true
    FROM usr02
    WHERE bname = @iv_request_id
    INTO @lv_is_sap_account.

  SELECT SINGLE
         @abap_true
    FROM zwms_t_user
    WHERE user_id = @iv_request_id
      AND administrator = 'X'
    INTO @DATA(lv_is_adm_account).

  DATA(is_adm_acct) = xsdbool( lv_is_sap_account = abap_true OR
                               lv_is_adm_account = abap_true ).

  IF is_adm_acct = abap_true.

  ELSE.
    " Validate Old PWD
    DATA(lv_old_salted_pwd) = iv_old_password && ls_wms_pwd-pwd_salt.
    DATA lv_old_pwd_hash TYPE string.

    TRY.
        cl_abap_message_digest=>calculate_hash_for_char(
          EXPORTING if_algorithm  = 'SHA512'
                    if_data       = lv_old_salted_pwd
          IMPORTING ef_hashstring = lv_old_pwd_hash ).
      CATCH cx_abap_message_digest.
        ev_type = 'E'.
        ev_msg  = 'Internal Error: Failed to calculate old password hash.'.
        RETURN.
    ENDTRY.

    IF lv_old_pwd_hash <> ls_wms_pwd-pwd_hash.
      ev_type = 'E'.
      ev_msg  = 'Incorrect old password.'.
      RETURN.
    ENDIF.

  ENDIF.

  " =======================================================================
  " Generate a New Password
  " =======================================================================
  DATA lv_pwd_check_msg TYPE string.
  DATA ls_bapipwd       TYPE bapipwd.
  ls_bapipwd-bapipwd = iv_new_password.

  CALL FUNCTION 'PASSWORD_FORMAL_CHECK'
    EXPORTING
      password        = ls_bapipwd
      security_policy = 'ZPASSWORD_POLICY_01'
    IMPORTING
      msgtext         = lv_pwd_check_msg
    EXCEPTIONS
      OTHERS          = 1.
  IF sy-subrc <> 0.
    ev_type = 'E'.
    ev_msg  = lv_pwd_check_msg.
    RETURN.
  ENDIF.

  " New Salt
  TRY.
      DATA(lv_new_salt) = cl_system_uuid=>create_uuid_c32_static( ).
    CATCH cx_uuid_error.
      ev_type = 'E'.
      ev_msg  = 'Internal Error: Failed to generate new Salt.'.
      RETURN.
  ENDTRY.

  DATA(lv_new_salted_pwd) = iv_new_password && lv_new_salt.
  DATA lv_new_pwd_hash TYPE string.

  TRY.
      cl_abap_message_digest=>calculate_hash_for_char(
        EXPORTING if_algorithm  = 'SHA512'
                  if_data       = lv_new_salted_pwd
        IMPORTING ef_hashstring = lv_new_pwd_hash ).
    CATCH cx_abap_message_digest.
      ev_type = 'E'.
      ev_msg  = 'Internal Error: Failed to calculate new Hash.'.
      RETURN.
  ENDTRY.

  " =======================================================================
  " Update Database
  " =======================================================================
  UPDATE zwms_t_user SET pwd_salt    = lv_new_salt
                         pwd_hash    = lv_new_pwd_hash
                         pwd_initial = abap_false
                   WHERE user_id     = lv_user_id.

  IF sy-subrc = 0.
    ev_type = 'S'.
    ev_msg  = 'Password changed successfully.'.
  ELSE.
    ev_type = 'E'.
    ev_msg  = 'Database update failed.'.
  ENDIF.






ENDFUNCTION.
