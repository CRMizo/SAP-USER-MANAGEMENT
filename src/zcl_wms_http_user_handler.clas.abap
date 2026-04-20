CLASS zcl_wms_http_user_handler DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_http_extension.
ENDCLASS.


CLASS zcl_wms_http_user_handler IMPLEMENTATION.
  METHOD if_http_extension~handle_request.
    data lv_action   type ZWMS_USER_ACTION.
    DATA lv_data_in  TYPE zwms_user_data_in.
    DATA lv_data_out TYPE zwms_user_data_out.

    " Set Header Field
    server->response->set_header_field( name  = 'Access-Control-Allow-Origin'
                                        value = '*' ).

    IF server->request->get_header_field( '~request_method' ) = 'OPTIONS'.
      server->response->set_status( code   = 200
                                    reason = 'OK' ).
      RETURN.
    ENDIF.

    " Get the HTTP method
    DATA(lv_method) = server->request->get_header_field( '~request_method' ).
    lv_action = server->request->get_form_field( 'action' ).
    IF lv_action IS INITIAL.
      lv_action = server->request->get_header_field( 'action' ).
    ENDIF.

    lv_action = to_upper( lv_action ).

    IF lv_method <> 'POST'.
      RETURN.
    ENDIF.

    " Get Input (JSON)
    DATA(lv_xdata) = server->request->get_data( ).

    IF lv_xdata IS NOT INITIAL.
      TRY.
          lv_data_in = cl_abap_codepage=>convert_from( source   = lv_xdata
                                                       codepage = `UTF-8` ).
        CATCH cx_parameter_invalid_range
              cx_sy_codepage_converter_init
              cx_sy_conversion_codepage
              cx_parameter_invalid_type INTO DATA(lx_error).
          lv_data_out = |\{"EV_TYPE":"E","EV_MSG":"JSON Payload encoding error: { lx_error->get_text( ) }"\}|.
          server->response->set_header_field( name  = 'Content-Type'
                                              value = 'application/json; charset=utf-8' ).
          server->response->set_cdata( data = lv_data_out ).
          server->response->set_status( code   = 400
                                        reason = 'Bad Request' ).
          RETURN.
      ENDTRY.
    ENDIF.

    IF lv_action IS NOT INITIAL.
      CALL FUNCTION 'ZWMS_FM_USER_MAIN'
        EXPORTING action   = lv_action
                  data_in  = lv_data_in
        IMPORTING data_out = lv_data_out.

      server->response->set_header_field( name  = 'Content-Type'
                                          value = 'application/json; charset=utf-8' ).
      server->response->set_cdata( data = lv_data_out ).
      server->response->set_status( code   = 200
                                    reason = 'OK' ).
    ELSE.
      server->response->set_status( code   = 400
                                    reason = 'Bad Request' ).
      server->response->set_cdata( 'Missing action parameter in URL or Header.' ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
