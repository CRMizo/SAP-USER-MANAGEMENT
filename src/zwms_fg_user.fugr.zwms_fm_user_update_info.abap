FUNCTION zwms_fm_user_update_info.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_USER_ID) TYPE  ZWMS_USER_ID
*"     VALUE(IV_USER_NAME) TYPE  ZWMS_USER_NAME OPTIONAL
*"     VALUE(IS_ADDICTIONAL) TYPE  ZWMS_S_USER_PROPERTIES OPTIONAL
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

  " Check If SAP account
  SELECT SINGLE @abap_true FROM usr02
    WHERE bname = @lv_user_id
    INTO @DATA(lv_is_sap_account).

  IF lv_is_sap_account = abap_true.
    ev_type = 'E'.
    ev_msg  = 'Action Denied: Cannot update SAP standard account via this interface. Please goto SAP.'.
    RETURN.
  ENDIF.

  SELECT SINGLE @abap_true FROM zwms_t_user
    WHERE user_id = @lv_user_id
    INTO @DATA(lv_user_exists).

  IF lv_user_exists = abap_false.
    ev_type = 'E'.
    ev_msg  = 'User ID does not exist in WMS Custom Table.'.
    RETURN.
  ENDIF.

  UPDATE zwms_t_user SET user_name     = @iv_user_name,
                         lock_status   = @is_addictional-lock_status,
                         email         = @is_addictional-email,
                         gender        = @is_addictional-gender,
                         phone         = @is_addictional-phone,
                         administrator = @is_addictional-administrator
                   WHERE user_id = @lv_user_id.

  IF sy-subrc = 0.
    ev_type = 'S'.
    ev_msg  = 'User information updated successfully.'.
    commit work.
  ELSE.
    ev_type = 'E'.
    ev_msg  = 'Database update failed.'.
  ENDIF.
ENDFUNCTION.
