FUNCTION zwms_fm_user_get_info.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_USER_ID) TYPE  ZWMS_USER_ID
*"     VALUE(IV_EXACT) TYPE  CHAR1 OPTIONAL
*"  EXPORTING
*"     VALUE(ES_USER_INFO) TYPE  ZWMS_S_USER_INFO
*"     VALUE(EV_TYPE) TYPE  BAPI_MTYPE
*"     VALUE(EV_MSG) TYPE  BAPI_MSG
*"  TABLES
*"      ET_USER_INFO STRUCTURE  ZWMS_S_USER_INFO OPTIONAL
*"----------------------------------------------------------------------
  CLEAR et_user_info[].

  DATA: ls_user_info TYPE zwms_s_user_info,
        ls_address   TYPE bapiaddr3,
        lt_return    TYPE TABLE OF bapiret2.
  DATA: r_userid TYPE RANGE OF zwms_t_user-user_id.

  CHECK iv_user_id IS NOT INITIAL.


  DATA(lv_user_id) = |%{ to_upper( iv_user_id ) }%|.
  IF iv_exact = 'X'.
    r_userid = VALUE #( ( sign = 'I'
                          option = 'EQ'
                          low = to_upper( iv_user_id ) ) ).
  ENDIF.


  " =======================================================================
  " SAP Standard Account
  " =======================================================================
  SELECT bname,
         erdat
    FROM usr02
    WHERE bname LIKE @lv_user_id
      AND bname IN @r_userid
  UNION ALL
  SELECT map~sap_user AS bname,
         usr02~erdat
    FROM ZWMS_T_USER_map AS map
    INNER JOIN usr02 ON map~sap_user = usr02~bname
    WHERE map~user_id LIKE @lv_user_id
      AND map~user_id IN @r_userid
    INTO TABLE @DATA(lt_sap_users).
  IF sy-subrc = 0.
    LOOP AT lt_sap_users INTO DATA(ls_sap_user).
      CLEAR: ls_user_info, ls_address, lt_return[].

      " Get Mapping ID
      SELECT SINGLE
             user_id
        FROM zwms_t_user_map
        WHERE sap_user = @ls_sap_user-bname
        INTO @DATA(lv_map_id).

      ls_user_info-mapping_id    = lv_map_id.
      ls_user_info-user_id       = ls_sap_user-bname.
      ls_user_info-creation_date = ls_sap_user-erdat.
      ls_user_info-administrator = 'X'.
      ls_user_info-is_sap_user = 'X'.

      CALL FUNCTION 'BAPI_USER_GET_DETAIL'
        EXPORTING
          username = ls_sap_user-bname
        IMPORTING
          address  = ls_address
        TABLES
          return   = lt_return
        EXCEPTIONS
          OTHERS   = 1.

      IF sy-subrc = 0.
        ls_user_info-user_name = ls_address-fullname.
        ls_user_info-email     = ls_address-e_mail.
      ENDIF.

      APPEND ls_user_info TO et_user_info.
    ENDLOOP.

    IF iv_exact = 'X'.
      ev_type = 'S'.
      ev_msg = 'SAP Standard Account.'.
      RETURN.
    ENDIF.
  ENDIF.

  " =======================================================================
  " WMS Customize Account
  " =======================================================================
  SELECT *
    FROM zwms_t_user
    WHERE user_id LIKE @lv_user_id
      AND user_id IN @r_userid
    APPENDING CORRESPONDING FIELDS OF TABLE @et_user_info.
  IF sy-subrc = 0.
    ev_type = 'S'.
    ev_msg  = 'Retrieved from WMS Custom Table.'.
  ELSEIF et_user_info[] IS INITIAL.
    ev_type = 'E'.
    ev_msg  = 'User not found in any source.'.
  ENDIF.

  IF et_user_info[] IS NOT INITIAL.
    ev_type = 'S'.
  ENDIF.
ENDFUNCTION.
