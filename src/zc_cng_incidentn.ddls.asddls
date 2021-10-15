@EndUserText.label: 'Projection View for Incident (UUID)'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define root view entity ZC_CNG_IncidentN
  as projection on ZI_CNG_IncidentN
{
  key IncidentUUID,
      TicketNo,
      RaisedBy,
      Description,
      Status
}
