CLASS zcl_cng_btoken_test DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_bearer,
             acces_token TYPE string,
             token_type  TYPE string,
             expires_in  TYPE n LENGTH 8,
             scope       TYPE string,
             jti         TYPE string,
           END OF ty_bearer.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_cng_btoken_test IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    DATA: ls_result TYPE ty_bearer.

    DATA(lv_dest) = cl_http_destination_provider=>create_by_url( |https://fffbbb97trial.authentication.eu10.hana.ondemand.com/oauth/token| ).
    DATA(lo_web_http_client) = cl_web_http_client_manager=>create_by_http_destination( i_destination = lv_dest ).
    DATA(lo_web_http_request) = lo_web_http_client->get_http_request( ).
    lo_web_http_request->set_form_field(
      EXPORTING
        i_name  = 'grant_type'
        i_value = 'client_credentials'
    ).
    lo_web_http_request->set_form_field(
      EXPORTING
        i_name  = 'client_id'
        i_value = 'sb-clone-8499fdbb-8aad-4341-9b0f-cbb399c40f8f!b60667|workflow!b10150'
    ).
    lo_web_http_request->set_form_field(
      EXPORTING
        i_name  = 'client_secret'
        i_value = 'e0b3edde-dfa9-443b-9caa-e9c8b6ab38bf$DWoPbM-lzywaHQoV9G0qWAhGYbcncJevQkZJtcOUQwQ='
    ).

    lo_web_http_request->set_header_fields( VALUE #(
        (  name = 'Accept' value = 'application/json' )
        (  name = 'Content-Type' value = 'application/x-www-form-urlencoded' )
        ) ).

    DATA(lo_web_http_response) = lo_web_http_client->execute( if_web_http_client=>get ).
    DATA(lv_response) = lo_web_http_response->get_text( ).

*    /ui2/cl_json=>deserialize(
*       EXPORTING json = lv_response pretty_name = /ui2/cl_json=>pretty_mode-camel_case CHANGING data = ls_result ).

    SPLIT lv_response AT '"' INTO TABLE DATA(lt_response).

    out->write( VALUE #( lt_response[ 4 ] OPTIONAL ) ).
    out->write( lv_response ).
*    xco_cp_json=>data->from_string( lv_response )->apply(
*        VALUE #(
*          ( xco_cp_json=>transformation->pascal_case_to_underscore )
*          ( xco_cp_json=>transformation->boolean_to_abap_bool )
*          ( xco_cp_json=>transformation->underscore_to_pascal_case ) )
*        )->write_to( REF #( ls_result ) ).
*    out->write( ls_result-accestoken ).
*    out->write( lv_response ).
  ENDMETHOD.
ENDCLASS.
