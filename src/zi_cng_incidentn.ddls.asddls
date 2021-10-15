@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Incident basic view (UUID)'
define root view entity ZI_CNG_IncidentN
  as select from zcng_incident_n as Incident
{
      @EndUserText.label: 'Incident UUID'
  key incident_uuid as IncidentUUID,
      @EndUserText.label: 'Ticket Number'
      ticket_no     as TicketNo,
      @EndUserText.label: 'Raised By'
      raised_by     as RaisedBy,
      @EndUserText.label: 'Description'
      description   as Description,
      @EndUserText.label: 'Status'
      status        as Status
}
