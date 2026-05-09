CLASS zcl_wms_user_totp_utility DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-METHODS generate_secret_key
      IMPORTING
        !iv_length     TYPE i DEFAULT 32  " 通常TOTP密钥长度为16或32
      RETURNING
        VALUE(rv_key)  TYPE string.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_wms_user_totp_utility IMPLEMENTATION.
  METHOD generate_secret_key.
    " Base32
    CONSTANTS lc_base32_chars TYPE string VALUE 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'.

    DATA: lo_rand_int TYPE REF TO cl_abap_random_int,
          lv_seed     TYPE i,
          lv_index    TYPE i.

    " random seed
    GET TIME STAMP FIELD DATA(lv_timestamp).
    lv_seed = lv_timestamp MOD 2147483647 .


    lo_rand_int = cl_abap_random_int=>create(
                    seed = lv_seed
                    min  = 0
                    max  = 31
                  ).

    CLEAR rv_key.

    DO iv_length TIMES.
      lv_index = lo_rand_int->get_next( ).
      rv_key = rv_key && lc_base32_chars+lv_index(1).
    ENDDO.

  ENDMETHOD.
ENDCLASS.
