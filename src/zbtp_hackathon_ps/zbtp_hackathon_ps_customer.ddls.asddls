@EndUserText.label: 'Kunde'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_BTP_HACKATHON_CUSTOMER_IMP'
@UI: {
  headerInfo: { typeName: 'Customer',
                typeNamePlural: 'Customers',
                title: { type: #STANDARD, label: 'Customer', value: 'Customer' }
              }
     }
define root custom entity zbtp_hackathon_ps_customer
{
      @UI.facet   : [{ id: 'DeliveryData',
                               purpose         : #STANDARD,
                               type            : #IDENTIFICATION_REFERENCE,
                               label           : 'Customer Data',
                               position        : 10 }]
      @UI         : {
              identification         : [{ position: 10 }
      //                                        { position: 10, type: #FOR_ACTION, dataAction: 'lockCustomer', label: 'Lock Customer' },
      //                                        { position: 10, type: #FOR_ACTION, dataAction: 'releaseCustomer', label: 'Release Customer' }
                                       ],
              lineItem               : [{ position: 10 }
      //                                        { position: 10, type: #FOR_ACTION, dataAction: 'lockCustomer', label: 'Lock Customer' },
      //                                        { position: 10, type: #FOR_ACTION, dataAction: 'releaseCustomer', label: 'Release Customer' }
                                        ]}
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
      OpenItems   : abap.dec(15,2);
      @UI         : {
      identification               : [{ position: 60 }],
      lineItem    : [{ position: 60 }] }
      @EndUserText.label : 'Locked'
      isLocked    : abap.char(1);
}
