FUNCTION zwms_fm_user_get_info.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_USER_ID) TYPE  ZWMS_USER_ID
*"  EXPORTING
*"     VALUE(EV_USER_NAME) TYPE  ZWMS_USER_NAME
*"     VALUE(EV_GENDER) TYPE  CHAR1
*"     VALUE(EV_EMAIL) TYPE  AD_SMTPADR
*"     VALUE(EV_PHONE) TYPE  AD_TLNMBR
*"     VALUE(EV_CREATION_DATE) TYPE  XUERDAT
*"     VALUE(EV_TYPE) TYPE  BAPI_MTYPE
*"     VALUE(EV_MSG) TYPE  BAPI_MSG
*"----------------------------------------------------------------------
  DATA(lv_user_id) = to_upper( iv_user_id ).

  " =======================================================================
  " SAP Standard Account
  " =======================================================================
  SELECT SINGLE bname,
                erdat
    FROM usr02
    WHERE bname = @lv_user_id
    INTO @DATA(ls_user02).
  IF sy-subrc = 0.
    ev_creation_date = ls_user02-erdat.

    DATA ls_address TYPE bapiaddr3.
    DATA lt_return  TYPE TABLE OF bapiret2.
    CALL FUNCTION 'BAPI_USER_GET_DETAIL'
      EXPORTING  username = CONV bapibname-bapibname( lv_user_id )
      IMPORTING  address  = ls_address
      TABLES     return   = lt_return
      EXCEPTIONS OTHERS   = 1.
    IF sy-subrc = 0.
      ev_user_name = ls_address-fullname.
      ev_email     = ls_address-e_mail.
    ENDIF.

    ev_type = 'S'.
    ev_msg = 'SAP Standard Account.'.
    RETURN.
  ENDIF.

  " =======================================================================
  " WMS Customize Account
  " =======================================================================
  SELECT SINGLE user_name,
                gender,
                email,
                phone,
                creation_date
    FROM zwms_t_user
    WHERE user_id = @lv_user_id
    INTO ( @ev_user_name, @ev_gender, @ev_email, @ev_phone, @ev_creation_date ).
  IF sy-subrc = 0.
    ev_type = 'S'.
    ev_msg  = 'Retrieved from WMS Custom Table.'.
  ELSE.
    ev_type = 'E'.
    ev_msg  = 'User not found in any source.'.
  ENDIF.
ENDFUNCTION.
