FUNCTION zwms_fm_user_totp_validate.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_USER_ID) TYPE  ZWMS_USER_ID
*"     VALUE(IV_SECRET_KEY) TYPE  STRING
*"     VALUE(IV_TOTP_CODE) TYPE  STRING
*"  EXPORTING
*"     VALUE(EV_TYPE) TYPE  BAPI_MTYPE
*"     VALUE(EV_MSG) TYPE  BAPI_MSG
*"----------------------------------------------------------------------
  IF iv_user_id IS INITIAL.
    ev_type = 'E'.
    ev_msg = 'User ID cannot be empty.'.
  ENDIF.

  IF iv_totp_code IS INITIAL.
    ev_type = 'E'.
    ev_msg  = 'TOTP cannot be empty.'.
    RETURN.
  ENDIF.

  DATA(lv_user_id) = to_upper( iv_user_id ).

  DATA(lv_secret_key) = iv_secret_key.
  IF lv_secret_key IS INITIAL.
    SELECT SINGLE secret_key
      FROM zwms_d_totpkey
      WHERE user_id = @lv_user_id
      INTO @lv_secret_key.
  ENDIF.

  TRY.
      DATA(current_totp) = zcl_wms_user_totp_generator=>get_instance( im_secret_key = lv_secret_key )->get_totp( ).
    CATCH cx_demo_dyn_t100.
      ev_type = 'E'.
      ev_msg  = 'Generate TOTP Code error.'.
      RETURN.
  ENDTRY.

  IF current_totp = iv_totp_code.
    ev_type = 'S'.
    ev_msg = 'Successfully.'.
  ELSE.
    ev_type = 'E'.
    ev_msg = 'The TOTP does not match.'.
  ENDIF.
ENDFUNCTION.
