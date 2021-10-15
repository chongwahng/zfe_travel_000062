CLASS zcl_cng_xco_test DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_cng_xco_test IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    DATA(lo_json_builder) = xco_cp_json=>data->builder( ).

    lo_json_builder->begin_object(
        )->add_member( 'definitionId' )->add_string( 'cng.com.approvalprocess'
        )->add_member( 'context' )->begin_object(
        )->add_member( 'IncidentUUID' )->add_string( '7cd44fff-036a-4155-b0d2-f5a4dfbcee92'
        )->add_member( 'TicketNo' )->add_string( '1'
        )->add_member( 'RaisedBy' )->add_string( 'CB00001223'
        )->add_member( 'Description' )->add_string( 'testing only'
        )->add_member( 'Status' )->add_string( 'Created'
        )->end_object(  )->end_object( ).

    DATA(lv_json_string) = lo_json_builder->get_data( )->to_string( ).

    out->write( lv_json_string ).

    DATA(lo_uuid) = xco_cp_uuid=>format->c36->to_uuid( '7cd44fff-036a-4155-b0d2-f5a4dfbcee92' ).

    " LV_UUID_C32 will hold the value 7CD44FFF036A4155B0D2F5A4DFBCEE92
    DATA(lv_uuid_c32) =  CONV sysuuid_c32( xco_cp_uuid=>format->c32->from_uuid( lo_uuid ) ).
    out->write( lv_uuid_c32 ).

    DATA(lo_uuid_c32) = xco_cp_uuid=>format->c32->to_uuid( lv_uuid_c32 ).
    DATA(lv_uuid_c36) = xco_cp=>string( CONV sysuuid_c36( xco_cp_uuid=>format->c36->from_uuid( lo_uuid_c32 ) ) )->to_lower_case(  )->value.
    out->write( lv_uuid_c36 ).
  ENDMETHOD.
ENDCLASS.
