
CLASS lcl_buffer DEFINITION CREATE PRIVATE.
  "SAP Help - https://help.sap.com/docs/btp/sap-abap-restful-application-programming-model/implementing-buffer-class
  PUBLIC SECTION.
    "types used in get_data
    TYPES: BEGIN OF ts_message,
             customer TYPE zbtp_hack_i_ce_customer-Customer,
             symsg    TYPE symsg,
             fields   TYPE string_table,
           END OF ts_message,
           tt_customer        TYPE STANDARD TABLE OF zbtp_hack_i_ce_customer,
           tt_customer_in     TYPE TABLE FOR READ IMPORT zbtp_hack_i_ce_customer,
           tt_customer_out    TYPE TABLE FOR READ RESULT zbtp_hack_i_ce_customer,
           tt_customer_failed TYPE TABLE FOR FAILED zbtp_hack_i_ce_customer,
           tt_message         TYPE STANDARD TABLE OF ts_message,

           "types used in put_data
           tt_customer_upd    TYPE TABLE FOR UPDATE zbtp_hack_i_ce_customer,
           tt_customer_mapped TYPE TABLE FOR MAPPED zbtp_hack_i_ce_customer.

    CLASS-METHODS get_instance
      RETURNING VALUE(ro_instance) TYPE REF TO lcl_buffer.

    METHODS: get_data
      IMPORTING it_customer        TYPE tt_customer_in OPTIONAL
      EXPORTING et_customer        TYPE tt_customer_out
                et_customer_failed TYPE tt_customer_failed
                et_message         TYPE tt_message,
      put_data
        IMPORTING it_customer_upd    TYPE tt_customer_upd
        EXPORTING et_customer_failed TYPE tt_customer_failed
                  et_message         TYPE tt_message.

  PRIVATE SECTION.
    CLASS-DATA: go_instance TYPE REF TO lcl_buffer.
    DATA: mt_customer       TYPE tt_customer.

ENDCLASS.

CLASS lcl_buffer IMPLEMENTATION.

  METHOD get_instance.
    "SAP Help - https://help.sap.com/docs/btp/sap-abap-restful-application-programming-model/implementing-buffer-class
    IF go_instance IS NOT BOUND.
      go_instance = NEW #( ).
    ENDIF.
    ro_instance = go_instance.
  ENDMETHOD.

  METHOD get_data.
    "SAP Help - https://help.sap.com/docs/btp/sap-abap-restful-application-programming-model/implementing-buffer-class

    DATA: lt_customer        TYPE STANDARD TABLE OF zhack_customer.
    DATA: ls_result         LIKE LINE OF et_customer.
    DATA: lt_customer_id      TYPE STANDARD TABLE OF zhack_customer-customer.
    DATA: lt_filter         TYPE RANGE OF zhack_customer-customer.
    DATA: ls_filter         LIKE LINE OF lt_filter.
    DATA: lt_customer_ce      TYPE STANDARD TABLE OF zbtp_hack_i_ce_customer.
    FIELD-SYMBOLS: <fs_customer_ce> LIKE LINE OF lt_customer_ce.

    IF it_customer IS SUPPLIED.

      LOOP AT it_customer ASSIGNING FIELD-SYMBOL(<fs_customer>).
        IF line_exists( mt_customer[ customer = <fs_customer>-customer ] ).
          ls_result = CORRESPONDING #( mt_customer[ customer = <fs_customer>-customer ] ).
          " collect from buffer for result
          APPEND ls_result TO et_customer.
        ELSE.
          " collect to retrieve from persistence
          APPEND <fs_customer>-customer TO lt_customer_id.
        ENDIF.
      ENDLOOP.

      IF lt_customer_id IS NOT INITIAL.
        TRY.
            "Instantiate Client Proxy
            zbtp_cl_hack_onprem_connect=>get_client_proxy( EXPORTING api_name = 'ZUI_BTPUSECASE001CUSTOMER'
                                                       IMPORTING ro_odata_client_proxy = DATA(lo_client_proxy) ).

            "Create Read Request
            DATA(lo_read_request) = lo_client_proxy->create_resource_for_entity_set( 'CUSTOMER' )->create_request_for_read( ).

            lt_filter = VALUE #( FOR customer_id IN lt_customer_id ( sign = 'I' option = 'EQ' low = customer_id ) ).
            DATA(lo_filter) = lo_read_request->create_filter_factory( )->create_by_range( iv_property_path = 'CUSTOMER'
                                                                                     it_range         = lt_filter ).
            lo_read_request->set_filter( lo_filter ).

            DATA(lo_response) = lo_read_request->execute( ).

            " get relevant data sets
            lo_response->get_business_data( IMPORTING et_business_data = lt_customer ).

            " add local data
            IF lt_customer IS NOT INITIAL.

              " Map OData service to custom entity
              lt_customer_ce = CORRESPONDING #( lt_customer ).

              SELECT * FROM zbtpuc001 FOR ALL ENTRIES IN @lt_customer_ce WHERE customer = @lt_customer_ce-Customer INTO TABLE @DATA(lt_btpuc001).

              LOOP AT lt_customer_ce ASSIGNING FIELD-SYMBOL(<fs_data>).
                IF line_exists( lt_btpuc001[ customer =  <fs_data>-Customer ] ).
                  <fs_data>-open_items = lt_btpuc001[ customer =  <fs_data>-Customer ]-open_items.
                  <fs_data>-is_locked = lt_btpuc001[ customer =  <fs_data>-Customer ]-is_locked.

                  ls_result = CORRESPONDING #( <fs_data> ).
                  APPEND <fs_data> TO mt_customer.
                  APPEND ls_result        TO et_customer.

                ELSE.
                  "Implement suitable error handling

*                  APPEND VALUE #( customer =  <fs_data>-Customer ) TO et_customer_failed.
*                  APPEND VALUE #( customer    = <fs_data>-Customer
*                                  symsg-msgty = 'E'
*                                  symsg-msgid = '<msg_class>'
*                                  symsg-msgno = '<msg_no>'
*                                  symsg-msgv1 = <fs_data>-Customer )
*                  TO et_message.
                ENDIF.
              ENDLOOP.
            ENDIF.

          CATCH  /iwbep/cx_gateway.
            "Implement suitable error handling
*            et_customer_failed = CORRESPONDING #( lt_customer_id MAPPING customer = table_line ).
*            et_message = CORRESPONDING #( lt_customer_id MAPPING customer = table_line ).
*            LOOP AT et_message ASSIGNING FIELD-SYMBOL(<fs_message>).
*              <fs_message>-symsg-msgty = 'E'.
*              <fs_message>-symsg-msgid = '/DMO/CM_SERV_CONS'.
*              <fs_message>-symsg-msgno = '001'.
*            ENDLOOP.
          CATCH cx_http_dest_provider_error.
            "handle exception
        ENDTRY.
      ENDIF.
    ELSE.
      et_customer = CORRESPONDING #( mt_customer ).
    ENDIF.

  ENDMETHOD.

  METHOD put_data.
    "SAP Help - https://help.sap.com/docs/btp/sap-abap-restful-application-programming-model/implementing-buffer-class
    get_data(
      EXPORTING it_customer        = CORRESPONDING #( it_customer_upd MAPPING %key = %key EXCEPT * )
      IMPORTING et_customer        = DATA(lt_customer)
                et_customer_failed = DATA(lt_customer_failed)
                et_message         = DATA(lt_message)
    ).

    LOOP AT it_customer_upd ASSIGNING FIELD-SYMBOL(<fs_customer_upd>).
      CHECK line_exists( lt_customer[ KEY entity COMPONENTS customer = <fs_customer_upd>-customer ] ).
      ASSIGN lt_customer[ KEY entity COMPONENTS customer = <fs_customer_upd>-customer ] TO FIELD-SYMBOL(<fs_customer>).

      IF <fs_customer_upd>-%control-open_items = if_abap_behv=>mk-on.
        <fs_customer>-open_items = <fs_customer_upd>-open_items.
      ENDIF.

      IF <fs_customer_upd>-%control-is_locked = if_abap_behv=>mk-on.
        <fs_customer>-is_locked = <fs_customer_upd>-is_locked.
      ENDIF.

      IF <fs_customer_upd>-%control-CreditLimit = if_abap_behv=>mk-on.
        <fs_customer>-CreditLimit = <fs_customer_upd>-CreditLimit.
      ENDIF.
    ENDLOOP.

    "save data in buffer
    mt_customer = CORRESPONDING #( lt_customer ) .
  ENDMETHOD.

ENDCLASS.

CLASS lhc_ZBTP_HACK_I_CE_CUSTOMER DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Customer RESULT result.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Customer.

    METHODS read FOR READ
      IMPORTING it_customer_read   FOR READ Customer
      RESULT    et_customeraddinfo.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Customer.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Customer RESULT result.

    METHODS lockcustomer FOR MODIFY
      IMPORTING keys FOR ACTION Customer~lockcustomer.

    METHODS releasecustomer FOR MODIFY
      IMPORTING keys FOR ACTION Customer~releasecustomer.
    METHODS change_credit_limit FOR MODIFY
      IMPORTING keys FOR ACTION customer~change_credit_limit.

ENDCLASS.

CLASS lhc_ZBTP_HACK_I_CE_CUSTOMER IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD update.
  "SAP Help - https://help.sap.com/docs/btp/sap-abap-restful-application-programming-model/implementing-modify
    DATA(lo_buffer) = lcl_buffer=>get_instance( ).

    lo_buffer->put_data(
        EXPORTING
          it_customer_upd      = entities
          IMPORTING
          et_customer_failed   = failed-customer
          et_message         = DATA(lt_message)
    ).
  ENDMETHOD.

  METHOD read.
  "SAP Help - https://help.sap.com/docs/btp/sap-abap-restful-application-programming-model/implementing-read
    DATA(lo_buffer) = lcl_buffer=>get_instance( ).

    lo_buffer->get_data(
      EXPORTING
        it_customer          = it_customer_read
      IMPORTING
        et_customer = et_customeraddinfo
        et_customer_failed   = failed-customer
    ).
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD get_instance_features.
  "SAP Help - https://help.sap.com/docs/ABAP_PLATFORM_NEW/fc4c71aa50014fd1b43721701471913d/eb060664a98c4275a3a4346d9c5b6707.html?version=202210.000
  "SAP Help - https://help.sap.com/docs/ABAP_PLATFORM_NEW/fc4c71aa50014fd1b43721701471913d/e8b7ee170d514f79ab3c93573d2a49cc.html?version=202210.000
    DATA(lo_buffer) = lcl_buffer=>get_instance( ).

    lo_buffer->get_data(
      EXPORTING
        it_customer          = VALUE #( FOR key IN keys
                                          ( %tky = key-Customer )
                                      )
      IMPORTING
        et_customer = DATA(lt_customer)
    ).

    " Set state for post action button
    result = VALUE #( FOR customer IN lt_customer
                       ( %tky                   = customer-Customer
                        %action-lockCustomer = COND #( WHEN customer-is_locked IS INITIAL
                                                          THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
                        %action-releaseCustomer = COND #( WHEN customer-is_locked IS NOT INITIAL
                                                          THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
                      ) ).

  ENDMETHOD.

  METHOD lockCustomer.
    DATA: lt_customer_upd TYPE lcl_buffer=>tt_customer_upd.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      APPEND VALUE #( customer = <key>-Customer is_locked = 'X' %control-is_locked = if_abap_behv=>mk-on ) TO lt_customer_upd.
    ENDLOOP.

    DATA(lo_buffer) = lcl_buffer=>get_instance( ).

    lo_buffer->put_data(
        EXPORTING
          it_customer_upd      = lt_customer_upd
          IMPORTING
          et_customer_failed   = failed-customer
          et_message         = DATA(lt_message)
    ).
  ENDMETHOD.

  METHOD releaseCustomer.
    DATA: lt_customer_upd TYPE lcl_buffer=>tt_customer_upd.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      APPEND VALUE #( customer = <key>-Customer is_locked = '' %control-is_locked = if_abap_behv=>mk-on ) TO lt_customer_upd.
    ENDLOOP.

    DATA(lo_buffer) = lcl_buffer=>get_instance( ).

    lo_buffer->put_data(
        EXPORTING
          it_customer_upd      = lt_customer_upd
          IMPORTING
          et_customer_failed   = failed-customer
          et_message         = DATA(lt_message)
    ).
  ENDMETHOD.

  METHOD change_credit_limit.
    DATA: lt_customer_upd TYPE lcl_buffer=>tt_customer_upd.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      APPEND VALUE #( customer              = <key>-Customer
                      creditlimit           = <key>-%param-CreditLimit
                      %control-creditlimit  = if_abap_behv=>mk-on )
              TO lt_customer_upd.
    ENDLOOP.

    DATA(lo_buffer) = lcl_buffer=>get_instance( ).

    lo_buffer->put_data(
        EXPORTING
          it_customer_upd      = lt_customer_upd
          IMPORTING
          et_customer_failed   = failed-customer
          et_message         = DATA(lt_message)
    ).
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZBTP_HACK_I_CE_CUSTOMER DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZBTP_HACK_I_CE_CUSTOMER IMPLEMENTATION.

  METHOD finalize.
    DATA(lo_buffer) = lcl_buffer=>get_instance( ).

    lo_buffer->get_data(
       IMPORTING
         et_customer = DATA(lt_customer)
    ).

    LOOP AT lt_customer ASSIGNING FIELD-SYMBOL(<fs_customer>).
      " Update On-premise persistence
      " Note: Normally this is not done as single request (due to performance),
      "       rather a batch call or mass update would be used
      zbtp_cl_hack_onprem_connect=>update_credit_limit(
        customer_id = <fs_customer>-Customer
        creditlimit = <fs_customer>-CreditLimit
      ).
    ENDLOOP.

  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
    DATA: ls_customeradd TYPE zbtpuc001.

    DATA(lo_buffer) = lcl_buffer=>get_instance( ).

    lo_buffer->get_data(
       IMPORTING
         et_customer = DATA(lt_customer)
    ).

    LOOP AT lt_customer ASSIGNING FIELD-SYMBOL(<fs_customer>).
      ls_customeradd = CORRESPONDING #( <fs_customer> ).

      " Update internal table
      MODIFY zbtpuc001 FROM @ls_customeradd.
    ENDLOOP.

  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
