CLASS zcl_cng_wf_client DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .

  PROTECTED SECTION.

  PRIVATE SECTION.
    METHODS:
      create_client
        IMPORTING iv_url           TYPE string
        RETURNING VALUE(rv_result) TYPE REF TO if_web_http_client
        RAISING   cx_static_check,

      get_bearer_token
        RETURNING VALUE(rv_result) TYPE string.
ENDCLASS.



CLASS zcl_cng_wf_client IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    TRY.
        DATA(lo_web_http_client) = me->create_client( |https://api.workflow-sap.cfapps.eu10.hana.ondemand.com/workflow-service/rest/v1/workflow-instances| ).
        DATA(lo_web_http_request) = lo_web_http_client->get_http_request( ).
        lo_web_http_request->set_header_fields( VALUE #(
            ( name = 'Authorization' value = |{ me->get_bearer_token(  ) }| )
            ( name = 'Accept' value = 'application/json' )
            ( name = 'Content-Type' value = 'application/json' )
         ) ).

        lo_web_http_request->set_text('{"definitionId": "cng.com.approvalprocess", "context": {"request": { "Name": "call from ABAP console class"},"response":{"Decision":""}}}').

        "set request method and execute request
        DATA(lo_web_http_response) = lo_web_http_client->execute( if_web_http_client=>post ).
        DATA(lv_response) = lo_web_http_response->get_text( ).

        out->write( |response:  { lv_response }| ).
      CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
        "error handling
      CATCH cx_static_check.
    ENDTRY.
  ENDMETHOD.

  METHOD create_client.
    DATA(lv_dest) = cl_http_destination_provider=>create_by_url( iv_url ).
    rv_result = cl_web_http_client_manager=>create_by_http_destination( i_destination = lv_dest ).
  ENDMETHOD.

  METHOD get_bearer_token.
    TRY.
        DATA(lv_dest) = cl_http_destination_provider=>create_by_url( |https://fffbbb97trial.authentication.eu10.hana.ondemand.com/oauth/token| ).
        DATA(lo_web_http_client) = cl_web_http_client_manager=>create_by_http_destination( i_destination = lv_dest ).
      CATCH cx_web_http_client_error.
      CATCH cx_http_dest_provider_error.
        "handle exception
    ENDTRY.

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

    TRY.
        DATA(lo_web_http_response) = lo_web_http_client->execute( if_web_http_client=>get ).
        DATA(lv_response) = lo_web_http_response->get_text( ).
        SPLIT lv_response AT '"' INTO TABLE DATA(lt_response).
        rv_result = |Bearer | && VALUE #( lt_response[ 4 ] OPTIONAL ).

      CATCH cx_web_http_client_error.
        "handle exception
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
