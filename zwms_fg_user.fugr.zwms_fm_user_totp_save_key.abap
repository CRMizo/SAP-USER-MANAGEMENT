FUNCTION zwms_fm_user_totp_save_key.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_USER_ID) TYPE  ZWMS_USER_ID
*"     VALUE(IV_SECRET_KEY) TYPE  STRING
*"  EXPORTING
*"     VALUE(EV_TYPE) TYPE  BAPI_MTYPE
*"     VALUE(EV_MSG) TYPE  BAPI_MSG
*"----------------------------------------------------------------------
  IF iv_user_id IS INITIAL.
    ev_type = 'E'.
    ev_msg  = 'User ID cannot be empty.'.
    RETURN.
  ENDIF.

  DATA(lv_user_id) = to_upper( iv_user_id ).
  SELECT SINGLE @abap_true FROM zwms_d_totpkey
    WHERE user_id = @lv_user_id
    INTO @DATA(has_secret_key).
  IF sy-subrc = 0.
    ev_type = 'E'.
    ev_msg  = 'Secret key already exist.'.
    RETURN.
  ENDIF.

  DATA ls_secret_key TYPE zwms_d_totpkey.
  ls_secret_key-user_id    = lv_user_id.
  ls_secret_key-secret_key = iv_secret_key.

  INSERT zwms_d_totpkey FROM ls_secret_key.
  IF sy-subrc = 0.
    ev_type = 'S'.
    ev_msg  = 'Verify successfully.'.
  ELSE.
    ev_type = 'E'.
    ev_msg = 'Save Secret key error.'.
  ENDIF.



ENDFUNCTION.
