FUNCTION zwms_fm_user_totp_generate_key.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_USER_ID) TYPE  ZWMS_USER_ID
*"  EXPORTING
*"     VALUE(EV_SECRET_KEY) TYPE  STRING
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

  ev_secret_key = zcl_wms_user_totp_utility=>generate_secret_key( ).

  IF ev_secret_key IS NOT INITIAL.
    ev_type = 'S'.
    ev_msg  = 'Generate Secret key successfully.'.
  ELSE.
    ev_type = 'E'.
    ev_msg  = 'Generate Secret key error.'.
    RETURN.
  ENDIF.


ENDFUNCTION.
