FUNCTION zwms_fm_user_mapping.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_USER_ID) TYPE  ZWMS_USER_ID
*"     VALUE(IV_USER_MAP) TYPE  ZWMS_USER_ID
*"  EXPORTING
*"     VALUE(EV_TYPE) TYPE  BAPI_MTYPE
*"     VALUE(EV_MSG) TYPE  BAPI_MSG
*"----------------------------------------------------------------------
  DATA(lv_user_id) = to_upper( iv_user_id ).
  DATA(lv_user_map) = to_upper( iv_user_map ).

  " Check If SAP account
  SELECT SINGLE @abap_true FROM usr02
    WHERE bname = @lv_user_id
    INTO @DATA(is_sap_account).
  IF sy-subrc <> 0.
    ev_type = 'E'.
    ev_msg = 'Only SAP Standard Account can maintain.'.
    RETURN.
  ENDIF.

  " Check if Mapping ID is available
  SELECT SINGLE @abap_true FROM zwms_t_user
    WHERE user_id = @lv_user_map
    INTO @DATA(is_user_exist).
  IF sy-subrc = 0.
    ev_type = 'E'.
    ev_msg = |{ lv_user_map }ID already exist, please replace.|.
    RETURN.
  ENDIF.

  DATA ls_user_map TYPE zwms_t_user_map.

  ls_user_map = VALUE #( sap_user = lv_user_id
                         user_id  = lv_user_map ).
  TRY.
      INSERT zwms_t_user_map FROM ls_user_map.
      IF sy-subrc = 0.
       ev_type = 'E'.
       ev_msg  = 'Update Successfully.'.
      endif.
    CATCH cx_root INTO DATA(zcx_db_error).
      ev_type = 'E'.
      ev_msg = zcx_db_error->get_text( ).
  ENDTRY.






ENDFUNCTION.
