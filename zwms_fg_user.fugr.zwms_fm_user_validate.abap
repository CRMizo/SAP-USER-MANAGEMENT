FUNCTION zwms_fm_user_validate.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_USER_ID) TYPE  ZWMS_USER_ID
*"     VALUE(IV_PASSWORD) TYPE  XUNCODE
*"  EXPORTING
*"     VALUE(EV_ADM) TYPE  ZWMS_USER_ADMINISTRATOR
*"     VALUE(EV_NEW_TOTP) TYPE  CHAR1
*"     VALUE(EV_TYPE) TYPE  BAPI_MTYPE
*"     VALUE(EV_MSG) TYPE  BAPI_MSG
*"----------------------------------------------------------------------
  IF iv_user_id IS INITIAL.
    ev_type = 'E'.
    ev_msg = 'User ID cannot be empty.'.
    RETURN.
  ENDIF.

  IF iv_password IS INITIAL.
    ev_type = 'E'.
    ev_msg  = 'Password cannot be empty.'.
    RETURN.
  ENDIF.

  DATA(lv_user_id) = to_upper( iv_user_id ).
  DATA lv_sap_account TYPE xubname.
  DATA lv_auth_success TYPE abap_bool.

  " if SAP account
  SELECT SINGLE bname FROM usr02
    WHERE bname = @lv_user_id
    INTO @lv_sap_account.
  IF sy-subrc <> 0.
    " Get SAP user mapping
    SELECT SINGLE sap_user FROM zwms_t_user_map
      WHERE user_id = @lv_user_id
      INTO @lv_sap_account.
  ENDIF.

  DATA pwdstate TYPE xupwdstate.
  IF lv_sap_account IS NOT INITIAL. " is_sap_account = abap_true.
    CALL 'INTERNET_USER_LOGON' ID 'AUTHTYPE' FIELD 'P'
         ID 'TESTMODE' FIELD space
         ID 'UNAME'    FIELD lv_sap_account
         ID 'PASSW'    FIELD iv_password
         ID 'PASSFLAG' FIELD pwdstate.
    IF sy-subrc = 0.
      lv_auth_success = abap_true.
      ev_adm          = abap_true.
    ELSE.
      ev_type = 'E'.
      ev_msg  = 'Incorrect password'.
      RETURN.
    ENDIF.

  ELSE.
    " --- WMS self-create User ---
    SELECT SINGLE * FROM zwms_t_user
      WHERE user_id = @lv_user_id
      INTO @DATA(ls_user).
    IF sy-subrc <> 0.
      ev_type = 'E'.
      ev_msg = 'User ID does not exists.'.
      RETURN.
    ENDIF.

    IF ls_user-lock_status = abap_true.
      ev_type = 'E'.
      ev_msg  = 'User ID is locked, please contact Administrator'.
      RETURN.
    ENDIF.

    " Concatenating the Password and Salt
    DATA(lv_salted_pwd) = iv_password && ls_user-pwd_salt.
    DATA lv_pwd_hash TYPE string.

    TRY.
        cl_abap_message_digest=>calculate_hash_for_char( EXPORTING if_algorithm  = 'SHA512'
                                                                   if_data       = lv_salted_pwd
                                                         IMPORTING ef_hashstring = lv_pwd_hash ).
      CATCH cx_abap_message_digest INTO DATA(lx_digest).
        ev_type = 'E'.
        ev_msg  = |Failed to calculate Hash:{ lx_digest->get_text( ) }|.
        RETURN.
    ENDTRY.

    IF lv_pwd_hash = ls_user-pwd_hash.
      " Password correct
      lv_auth_success = abap_true.
      ev_adm = ls_user-administrator.

      IF ls_user-fail_count > 0.
        UPDATE zwms_t_user SET fail_count = 0 WHERE user_id = iv_user_id.
      ENDIF.

    ELSE.
      " Password incorrect
      ev_type = 'E'.
      ls_user-fail_count += 1.
      ev_msg = |Incorrect password, you still have { 5 - ls_user-fail_count } chances.|.
      IF ls_user-fail_count >= 5.
        ls_user-lock_status = abap_true.
        ev_msg = 'Account has been locked due to too many failed attempts.'.
      ENDIF.

      UPDATE zwms_t_user SET fail_count = ls_user-fail_count
                             lock_status = ls_user-lock_status
                       WHERE user_id = iv_user_id.

    ENDIF.
  ENDIF.


  " TOTP Key Check
  IF lv_auth_success = abap_true.
    ev_type = 'S'.
    ev_msg  = 'Verification successfully.'.

    DATA(lv_totp_user_id) = COND #( WHEN lv_sap_account IS NOT INITIAL THEN lv_sap_account ELSE lv_user_id ).
    SELECT SINGLE @abap_true FROM zwms_d_totpkey
      WHERE user_id = @lv_totp_user_id
      INTO @DATA(has_key).

    ev_new_totp = COND #( WHEN has_key = abap_true THEN ' ' ELSE 'X' ).

  ENDIF.

ENDFUNCTION.
