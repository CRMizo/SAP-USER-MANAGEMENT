FUNCTION-POOL zwms_fg_user.                 "MESSAGE-ID ..

* INCLUDE LZWMS_FG_USERD...                  " Local class definition

TYPES: BEGIN OF ty_create_in,
         iv_user_id   TYPE zwms_user_id,
         iv_user_name TYPE zwms_user_name,
         iv_password  TYPE xuncode,
       END OF ty_create_in,

       BEGIN OF ty_validate_in,
         iv_user_id  TYPE zwms_user_id,
         iv_password TYPE xuncode,
       END OF ty_validate_in,

       BEGIN OF ty_out,
         ev_type TYPE bapi_mtype,
         ev_msg  TYPE bapi_msg,
       END OF ty_out.
