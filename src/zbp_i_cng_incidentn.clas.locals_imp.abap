CLASS lhc_Incident DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Incident RESULT result.

    METHODS set_default_values FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Incident~set_default_values.

    METHODS approve_incident FOR MODIFY
      IMPORTING keys FOR ACTION Incident~approve_incident RESULT result.

    METHODS reject_incident FOR MODIFY
      IMPORTING keys FOR ACTION Incident~reject_incident RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Incident RESULT result.

ENDCLASS.

CLASS lhc_Incident IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD set_default_values.
    READ ENTITIES OF ZI_CNG_IncidentN IN LOCAL MODE
        ENTITY Incident
        ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_incidents).

    DELETE lt_incidents WHERE TicketNo IS NOT INITIAL.

    CHECK lt_incidents IS NOT INITIAL.

    SELECT MAX( ticketno ) FROM ZI_CNG_IncidentN INTO @DATA(lv_latest_ticketno).

    LOOP AT lt_incidents ASSIGNING FIELD-SYMBOL(<ls_incident>).
      lv_latest_ticketno += 1.
      <ls_incident>-RaisedBy = sy-uname.
      <ls_incident>-TicketNo = lv_latest_ticketno.
      <ls_incident>-Status   = zbp_i_cng_incidentn=>c_status_pending.
    ENDLOOP.

    MODIFY ENTITIES OF ZI_CNG_IncidentN IN LOCAL MODE
        ENTITY Incident
        UPDATE FROM VALUE #( FOR ls_incident IN lt_incidents ( IncidentUUID = ls_incident-IncidentUUID
                                                               TicketNo     = ls_incident-TicketNo
                                                               RaisedBy     = ls_incident-RaisedBy
                                                               Status       = ls_incident-Status
                                                               %control-TicketNo = if_abap_behv=>mk-on
                                                               %control-RaisedBy = if_abap_behv=>mk-on
                                                               %control-Status   = if_abap_behv=>mk-on ) )
    FAILED DATA(ls_failed)
    REPORTED DATA(ls_reported).
  ENDMETHOD.

  METHOD approve_incident.
    MODIFY ENTITIES OF ZI_CNG_IncidentN IN LOCAL MODE
        ENTITY Incident
        UPDATE FROM VALUE #( FOR ls_key IN keys ( IncidentUUID = ls_key-IncidentUUID
                                                  Status = zbp_i_cng_incidentn=>c_status_approved
                                                  %control-Status = if_abap_behv=>mk-on ) )
        FAILED failed
        REPORTED reported.

    IF failed-incident IS INITIAL.
      READ ENTITIES OF ZI_CNG_IncidentN IN LOCAL MODE
          ENTITY Incident
          ALL FIELDS WITH VALUE #( FOR ls_key IN keys ( %key = ls_key-%key ) )
          RESULT DATA(lt_result).

      result = VALUE #( FOR ls_result IN lt_result ( %key = ls_result-%key
                                                     IncidentUUID = ls_result-IncidentUUID
                                                     %param-%data = ls_result-%data ) ).
    ENDIF.
  ENDMETHOD.

  METHOD reject_incident.
    MODIFY ENTITIES OF ZI_CNG_IncidentN IN LOCAL MODE
        ENTITY Incident
        UPDATE FROM VALUE #( FOR ls_key IN keys ( IncidentUUID = ls_key-IncidentUUID
                                                  Status = zbp_i_cng_incidentn=>c_status_rejected
                                                  %control-Status = if_abap_behv=>mk-on ) )
        FAILED failed
        REPORTED reported.

    IF failed-incident IS INITIAL.
      READ ENTITIES OF ZI_CNG_IncidentN IN LOCAL MODE
          ENTITY Incident
          ALL FIELDS WITH VALUE #( FOR ls_key IN keys ( %key = ls_key-%key ) )
          RESULT DATA(lt_result).

      result = VALUE #( FOR ls_result IN lt_result ( %key = ls_result-%key
                                                     IncidentUUID = ls_result-IncidentUUID
                                                     %param-%data = ls_result-%data ) ).
    ENDIF.
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF ZI_CNG_IncidentN IN LOCAL MODE
        ENTITY Incident
        FIELDS ( Status )
        WITH VALUE #( FOR ls_key IN keys ( %key = ls_key-%key ) )
        RESULT DATA(lt_incidents).

    result = VALUE #( FOR ls_incident IN lt_incidents ( %key = ls_incident-%key
                                                        %features-%action-approve_incident = COND #( WHEN ls_incident-Status = zbp_i_cng_incidentn=>c_status_pending
                                                                                                     THEN if_abap_behv=>fc-o-enabled
                                                                                                     ELSE if_abap_behv=>fc-o-disabled )
                                                        %features-%action-reject_incident = COND #( WHEN ls_incident-Status = zbp_i_cng_incidentn=>c_status_pending
                                                                                                    THEN if_abap_behv=>fc-o-enabled
                                                                                                    ELSE if_abap_behv=>fc-o-disabled ) ) ).
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZI_CNG_INCIDENTN DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

    METHODS create_client
      IMPORTING iv_url           TYPE string
      RETURNING VALUE(rv_result) TYPE REF TO if_web_http_client
      RAISING   cx_static_check.

    METHODS get_bearer_token
      RETURNING VALUE(rv_result) TYPE string.

    METHODS create_wf_instance
      IMPORTING is_incident TYPE ZI_CNG_IncidentN.

ENDCLASS.

CLASS lsc_ZI_CNG_INCIDENTN IMPLEMENTATION.

  METHOD save_modified.
    IF create-incident IS NOT INITIAL.
      LOOP AT create-incident ASSIGNING FIELD-SYMBOL(<ls_incident>).
        me->create_wf_instance( is_incident = CORRESPONDING #( <ls_incident> ) ).
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

  METHOD create_wf_instance.
    TRY.
        DATA(lo_web_http_client) = me->create_client( |https://api.workflow-sap.cfapps.eu10.hana.ondemand.com/workflow-service/rest/v1/workflow-instances| ).
        DATA(lo_web_http_request) = lo_web_http_client->get_http_request( ).
        lo_web_http_request->set_header_fields( VALUE #(
            ( name = 'Authorization' value = |{ me->get_bearer_token(  ) }| )
            ( name = 'Accept' value = 'application/json' )
            ( name = 'Content-Type' value = 'application/json' )
         ) ).

        DATA(lo_json_builder) = xco_cp_json=>data->builder( ).

        DATA(lo_uuid_c32) = xco_cp_uuid=>format->c32->to_uuid( |{ is_incident-IncidentUUID }| ).
        DATA(lv_uuid_c36) = xco_cp=>string( CONV sysuuid_c36( xco_cp_uuid=>format->c36->from_uuid( lo_uuid_c32 ) ) )->to_lower_case(  )->value.

        lo_json_builder->begin_object(
            )->add_member( 'definitionId' )->add_string( 'cng.com.approvalprocess'
            )->add_member( 'context' )->begin_object(
            )->add_member( 'IncidentUUID' )->add_string( |{ lv_uuid_c36 }|
            )->add_member( 'TicketNo' )->add_string( |{ is_incident-TicketNo }|
            )->add_member( 'RaisedBy' )->add_string( |{ is_incident-RaisedBy }|
            )->add_member( 'Description' )->add_string( |{ is_incident-Description }|
            )->add_member( 'Status' )->add_string( |{ is_incident-Status }|
            )->add_member( 'caller' )->add_string( |RAP|
            )->add_member( 'approvalStep' )->begin_object(
            )->add_member( 'decision' )->add_string( ||
            )->end_object(
            )->end_object(
            )->end_object( ).

        DATA(lv_json_string) = lo_json_builder->get_data( )->to_string( ).

        lo_web_http_request->set_text( lv_json_string ).
        "{"definitionId": "cng.com.approvalprocess", "context": {"request": { "Name": "from RAP service"},"response":{"Decision":""}}}.

        "set request method and execute request
        DATA(lo_web_http_response) = lo_web_http_client->execute( if_web_http_client=>post ).

      CATCH cx_http_dest_provider_error
            cx_web_http_client_error
            cx_web_message_error
            cx_static_check.
        "error handling
    ENDTRY.
  ENDMETHOD.

  METHOD get_bearer_token.
    TRY.
        DATA(lv_dest) = cl_http_destination_provider=>create_by_url( |https://81333ea9trial.authentication.eu10.hana.ondemand.com/oauth/token| ).
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
        i_value = 'sb-clone-c141add5-503f-4e44-8cd3-daee29012fb9!b113585|workflow!b10150'
    ).
    lo_web_http_request->set_form_field(
      EXPORTING
        i_name  = 'client_secret'
        i_value = '0dfcd112-7a2e-4c02-9024-721289f8fd60$ZhQk26IwRZGR8eb-6-S34E1qXa9fS4CafH4J-TT6-BU='
    ).

    lo_web_http_request->set_header_fields( VALUE #(
        (  name = 'Accept' value = 'application/json' )
        (  name = 'Content-Type' value = 'application/x-www-form-urlencoded' ) ) ).

    TRY.
        DATA(lo_web_http_response) = lo_web_http_client->execute( if_web_http_client=>get ).
        DATA(lv_response) = lo_web_http_response->get_text( ).
        SPLIT lv_response AT '"' INTO TABLE DATA(lt_response).
        rv_result = |Bearer | && VALUE #( lt_response[ 4 ] OPTIONAL ).

      CATCH cx_web_http_client_error INTO DATA(lx_client_err).
        rv_result = lx_client_err->get_longtext(   ).
        "handle exception
    ENDTRY.
  ENDMETHOD.

  METHOD create_client.
    DATA(lv_dest) = cl_http_destination_provider=>create_by_url( iv_url ).
    rv_result = cl_web_http_client_manager=>create_by_http_destination( i_destination = lv_dest ).
  ENDMETHOD.
ENDCLASS.
