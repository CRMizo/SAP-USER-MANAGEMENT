FUNCTION zwms_fm_user_main.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(ACTION) TYPE  ZWMS_USER_ACTION
*"     VALUE(DATA_IN) TYPE  ZWMS_USER_DATA_IN OPTIONAL
*"  EXPORTING
*"     VALUE(DATA_OUT) TYPE  ZWMS_USER_DATA_OUT
*"----------------------------------------------------------------------
  DATA: ls_create_in   TYPE ty_create_in,
        ls_validate_in TYPE ty_validate_in,
        ls_out         TYPE ty_out.

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
          ev_type     = ls_out-ev_type
          ev_msg      = ls_out-ev_msg.
      IF sy-subrc <> 0.
        ls_out-ev_type = 'E'.
        ls_out-ev_msg  = 'Failed to call ZWMS_FM_USER_VALIDATE'.
      ENDIF.
    WHEN OTHERS.
      ls_out-ev_type = 'E'.
      ls_out-ev_msg = |Unsupported Action { action }. 'CREATE' and 'VALIDATED' are supported.|.
  ENDCASE.

  data_out = /ui2/cl_json=>serialize( data = ls_out ).






ENDFUNCTION.
