// SAP Help - https://help.sap.com/docs/btp/sap-abap-restful-application-programming-model/implementing-query-for-service-consumption
@EndUserText.label: 'Custom entity for customer'
@ObjectModel.query.implementedBy: 'ABAP:ZBTP_CL_HACK_CUSTOMER_C_Q'
@UI: {
  headerInfo: { typeName: 'Customer',
                typeNamePlural: 'Customers',
                title: { type: #STANDARD, label: 'Customer', value: 'Customer' }
              }
     }
define root custom entity ZBTP_HACK_I_CE_CUSTOMER
{

      @UI.facet   : [{ id: 'DeliveryData',
                           purpose         : #STANDARD,
                           type            : #IDENTIFICATION_REFERENCE,
                           label           : 'Customer Data',
                           position        : 10 }]
      @UI         : {
              identification         : [{ position: 10 }],
              lineItem               : [{ position: 10 },
                                        { position: 10, type: #FOR_ACTION, dataAction: 'lockCustomer', label: 'Lock Customer' },
                                        { position: 10, type: #FOR_ACTION, dataAction: 'releaseCustomer', label: 'Release Customer' },
                                        { position: 30, type: #FOR_ACTION, dataAction: 'change_credit_limit', label: 'Change Credit Limit' }] }
      @EndUserText.label : 'Customer ID'
      @UI.selectionField             : [ { position: 10 } ]
  key Customer    : abap.char( 10 );
      @UI         : {
      identification               : [{ position: 20 }],
      lineItem    : [{ position: 20 }] }
      @EndUserText.label : 'First Name'
      @UI.selectionField             : [ { position: 20 } ]
      FirstName   : abap.char( 40 );
      @UI         : {
      identification               : [{ position: 30 }],
      lineItem    : [{ position: 30 }] }
      @EndUserText.label : 'Last Name'
      @UI.selectionField             : [ { position: 30 } ]
      LastName    : abap.char( 40 );
      @UI         : {
      identification               : [{ position: 40 }],
      lineItem    : [{ position: 40 }] }
      @EndUserText.label : 'Credit Limit'
      @UI.selectionField             : [ { position: 40 } ]
      CreditLimit : abap.dec( 15, 2 );
      @UI         : {
      identification               : [{ position: 50 }],
      lineItem    : [{ position: 50 }] }
      @EndUserText.label : 'Open Items'
      open_items  : abap.dec(15,2);
      @UI         : {
      identification               : [{ position: 60 }],
      lineItem    : [{ position: 60 }] }
      @EndUserText.label : 'Locked'
      is_locked   : abap.char(1);

}
