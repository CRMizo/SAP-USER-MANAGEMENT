FUNCTION-POOL zwms_fg_user.                 " MESSAGE-ID ..

" INCLUDE LZWMS_FG_USERD...                  " Local class definition

TYPES: BEGIN OF ty_create_in,
         iv_user_id     TYPE zwms_user_id,
         iv_user_name   TYPE zwms_user_name,
         iv_password    TYPE xuncode,
         iv_request_id  TYPE zwms_user_id,
         is_addictional TYPE zwms_s_user_properties,
       END OF ty_create_in.

TYPES: BEGIN OF ty_validate_in,
         iv_user_id  TYPE zwms_user_id,
         iv_password TYPE xuncode,
       END OF ty_validate_in.

TYPES: BEGIN OF ty_out,
         ev_type TYPE bapi_mtype,
         ev_msg  TYPE bapi_msg,
       END OF ty_out.

TYPES: BEGIN OF ty_validate_out,
         ev_adm  TYPE zwms_user_administrator,
         ev_type TYPE bapi_mtype,
         ev_msg  TYPE bapi_msg,
       END OF ty_validate_out.

TYPES: BEGIN OF ty_info_in,
         iv_user_id TYPE zwms_user_id,
         iv_exact   type c LENGTH 1,
       END OF ty_info_in.

TYPES: BEGIN OF ty_info_out,
         et_user_info TYPE zwms_tt_user_properties,
         ev_type      TYPE bapi_mtype,
         ev_msg       TYPE bapi_msg,
       END OF ty_info_out.

TYPES: BEGIN OF ty_change_pwd_in,
         iv_user_id      TYPE zwms_user_id,
         iv_old_password TYPE xuncode,
         iv_new_password TYPE xuncode,
         iv_request_id   TYPE zwms_user_id,
       END OF ty_change_pwd_in.

TYPES: BEGIN OF ty_update_in,
         iv_user_id     TYPE zwms_user_id,
         iv_user_name   TYPE zwms_user_name,
         is_addictional TYPE zwms_s_user_properties,
       END OF ty_update_in.

TYPES: BEGIN OF ty_update_out,
         ev_type TYPE bapi_mtype,
         ev_msg  TYPE bapi_msg,
       END OF ty_update_out.

TYPES: BEGIN OF ty_map_in,
         iv_user_id  TYPE zwms_user_id,
         iv_user_map TYPE zwms_user_id,
       END OF ty_map_in.
