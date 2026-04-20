FUNCTION zwms_fm_user_main.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(ACTION) TYPE  ZWMS_USER_ACTION
*"     VALUE(DATA_IN) TYPE  ZWMS_USER_DATA_IN OPTIONAL
*"  EXPORTING
*"     VALUE(DATA_OUT) TYPE  ZWMS_USER_DATA_OUT
*"----------------------------------------------------------------------
  DATA: ls_create_in    TYPE ty_create_in,
        ls_validate_in  TYPE ty_validate_in,
        ls_out          TYPE ty_out,
        ls_validate_out TYPE ty_validate_out.

  DATA: ls_info_in  TYPE ty_info_in,
        ls_info_out TYPE ty_info_out.

  DATA: ls_change_pwd_in  TYPE ty_change_pwd_in,
        ls_change_pwd_out TYPE ty_out.

  DATA: ls_update_in  TYPE ty_update_in,
        ls_update_out TYPE ty_update_out.

  CLEAR data_out.

  CASE action.
    WHEN 'CREATE'.
      /ui2/cl_json=>deserialize(
        EXPORTING
          json             = data_in
        CHANGING
          data             = ls_create_in
      ).

      CALL FUNCTION 'ZWMS_FM_USER_CREATE'
        EXPORTING
          iv_user_id              = ls_create_in-iv_user_id
          iv_user_name            = ls_create_in-iv_user_name
          iv_password             = ls_create_in-iv_password
          iv_request_id           = ls_create_in-iv_request_id
          is_addictional          = ls_create_in-is_addictional
        IMPORTING
          ev_type                 = ls_out-ev_type
          ev_msg                  = ls_out-ev_msg
        EXCEPTIONS
          failed_to_generate_salt = 1
          OTHERS                  = 2.
      IF sy-subrc <> 0.
        ls_out-ev_type = 'E'.
        ls_out-ev_msg  = 'Failed to call ZWMS_FM_USER_CREATE'.
      ENDIF.

      data_out = /ui2/cl_json=>serialize( data = ls_out ).

    WHEN 'VALIDATE'.
      /ui2/cl_json=>deserialize(
        EXPORTING
          json             = data_in
        CHANGING
          data             = ls_validate_in
      ).

      CALL FUNCTION 'ZWMS_FM_USER_VALIDATE'
        EXPORTING
          iv_user_id  = ls_validate_in-iv_user_id
          iv_password = ls_validate_in-iv_password
        IMPORTING
          ev_adm      = ls_validate_out-ev_adm
          ev_type     = ls_validate_out-ev_type
          ev_msg      = ls_validate_out-ev_msg.

      data_out = /ui2/cl_json=>serialize( data = ls_validate_out ).
      IF sy-subrc <> 0.
        ls_out-ev_type = 'E'.
        ls_out-ev_msg  = 'Failed to call ZWMS_FM_USER_VALIDATE'.
      ENDIF.
    WHEN 'INFO'.
      /ui2/cl_json=>deserialize(
        EXPORTING
          json             = data_in
        CHANGING
          data             = ls_info_in
      ).
      CALL FUNCTION 'ZWMS_FM_USER_GET_INFO'
        EXPORTING
          iv_user_id       = ls_info_in-iv_user_id
        IMPORTING
          ev_user_name     = ls_info_out-ev_user_name
          ev_creation_date = ls_info_out-ev_creation_date
          ev_type          = ls_info_out-ev_type
          ev_msg           = ls_info_out-ev_msg.
      IF sy-subrc <> 0.
        ls_info_out-ev_type = 'E'.
        ls_info_out-ev_msg  = 'Failed to call ZWMS_FM_USER_GET_INFO'.
      ENDIF.

      data_out = /ui2/cl_json=>serialize( data = ls_info_out ).
      RETURN.
    WHEN 'UPDATE_INFO'.
      /ui2/cl_json=>deserialize(
              EXPORTING
                json             = data_in
              CHANGING
                data             = ls_update_in
            ).

      CALL FUNCTION 'ZWMS_FM_USER_UPDATE_INFO'
        EXPORTING
          iv_user_id   = ls_update_in-iv_user_id
          iv_user_name = ls_update_in-iv_user_name
          is_addiction = ls_update_in-is_addictional
        IMPORTING
          ev_type      = ls_update_out-ev_type
          ev_msg       = ls_update_out-ev_msg.
      IF sy-subrc <> 0.
        ls_info_out-ev_type = 'E'.
        ls_info_out-ev_msg  = 'Failed to call ZWMS_FM_USER_UPDATE_INFO'.
      ENDIF.

      data_out = /ui2/cl_json=>serialize( data = ls_info_out ).
      RETURN.

    WHEN 'CHANGE_PWD'.
      /ui2/cl_json=>deserialize(
        EXPORTING
          json             = data_in
        CHANGING
          data             = ls_change_pwd_in
      ).

      CALL FUNCTION 'ZWMS_FM_USER_CHANGE_PWD'
        EXPORTING
          iv_user_id      = ls_change_pwd_in-iv_user_id
          iv_old_password = ls_change_pwd_in-iv_old_password
          iv_new_password = ls_change_pwd_in-iv_new_password
          iv_request_id   = ls_change_pwd_in-iv_request_id
        IMPORTING
          ev_type         = ls_change_pwd_out-ev_type
          ev_msg          = ls_change_pwd_out-ev_msg.
      IF sy-subrc <> 0.
        ls_info_out-ev_type = 'E'.
        ls_info_out-ev_msg  = 'Failed to call ZWMS_FM_USER_CHANGE_PWD'.
      ENDIF.

      data_out = /ui2/cl_json=>serialize( data = ls_change_pwd_out ).
      RETURN.

    WHEN OTHERS.
      ls_out-ev_type = 'E'.
      ls_out-ev_msg = |Unsupported Action { action }. 'CREATE' and 'VALIDATED' are supported.|.
  ENDCASE.








ENDFUNCTION.
