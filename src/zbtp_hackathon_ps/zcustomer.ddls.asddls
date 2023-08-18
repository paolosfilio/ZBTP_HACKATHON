/********** GENERATED on 08/17/2023 at 08:04:21 by CB9980000001**************/
 @OData.entitySet.name: 'Customer' 
 @OData.entityType.name: 'CustomerType' 
 define root abstract entity ZCUSTOMER { 
 key Customer : abap.char( 10 ) ; 
 @Odata.property.valueControl: 'Update_mc_vc' 
 Update_mc : abap_boolean ; 
 Update_mc_vc : RAP_CP_ODATA_VALUE_CONTROL ; 
 @Odata.property.valueControl: 'LastName_vc' 
 LastName : abap.char( 40 ) ; 
 LastName_vc : RAP_CP_ODATA_VALUE_CONTROL ; 
 @Odata.property.valueControl: 'FirstName_vc' 
 FirstName : abap.char( 40 ) ; 
 FirstName_vc : RAP_CP_ODATA_VALUE_CONTROL ; 
 @Odata.property.valueControl: 'CreditLimit_vc' 
 CreditLimit : abap.dec( 15, 2 ) ; 
 CreditLimit_vc : RAP_CP_ODATA_VALUE_CONTROL ; 
 
 } 
