CLASS zbtp_cl_hack_onprem_connect DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES: ty_t_customer    TYPE STANDARD TABLE OF zhack_customer,
           ty_t_ce_customer TYPE STANDARD TABLE OF zbtp_hack_i_ce_customer.

    CLASS-METHODS:
      get_client_proxy IMPORTING
                                 !api_name                    TYPE /iwbep/if_cp_runtime_types=>ty_entity_set_name
                       EXPORTING VALUE(ro_odata_client_proxy) TYPE REF TO /iwbep/if_cp_client_proxy
                       RAISING
                                 cx_http_dest_provider_error,
      set_filter IMPORTING
                   !request               TYPE REF TO if_rap_query_request
                 CHANGING
                   VALUE(ch_read_request) TYPE REF TO /iwbep/if_cp_request_read_list,
      enrich_data
        CHANGING
          VALUE(business_data) TYPE ty_t_ce_customer,
      update_credit_limit IMPORTING
                            customer_id TYPE zbtp_hack_i_ce_customer-Customer
                            creditlimit TYPE zbtp_hack_i_ce_customer-CreditLimit .

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zbtp_cl_hack_onprem_connect IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    DATA: lt_business_data TYPE TABLE OF zhack_customer,
          lo_response      TYPE REF TO /iwbep/if_cp_response_read_lst.

    TRY.
        "Instantiate Client Proxy
        zbtp_cl_hack_onprem_connect=>get_client_proxy( EXPORTING api_name = 'ZUI_BTPUSECASE001CUSTOMER'
                                                   IMPORTING ro_odata_client_proxy = DATA(lo_client_proxy) ).

        "Create Read Request
        DATA(lo_read_request) = lo_client_proxy->create_resource_for_entity_set( 'CUSTOMER' )->create_request_for_read( ).

        "Only read first 20 customers
        lo_read_request->set_top( 20 )->set_skip( 0 ).

        "Execute the request and retrieve the business data
        lo_response = lo_read_request->execute( ).

        "Map response to internal structure
        lo_response->get_business_data( IMPORTING et_business_data = lt_business_data ).

      CATCH /iwbep/cx_gateway.
        "handle exception
      CATCH cx_http_dest_provider_error.
        "handle exception
    ENDTRY.

    out->write( 'App to test On-Premise API ZUI_BTPUSECASE001CUSTOMER' ).
  ENDMETHOD.

  METHOD get_client_proxy.
    DATA:
      lo_http_client  TYPE REF TO if_web_http_client,
      lo_client_proxy TYPE REF TO /iwbep/if_cp_client_proxy,
      lo_request      TYPE REF TO /iwbep/if_cp_request_read_list,
      lo_response     TYPE REF TO /iwbep/if_cp_response_read_lst.

    TRY.
        " Create http client
        DATA(lo_destination) = cl_http_destination_provider=>create_by_comm_arrangement(
                                                     comm_scenario  = 'ZBTP_CS_HACKATHON'
                                                     comm_system_id = 'DEVSBXD35'
                                                     service_id     = 'ZBTP_OS_CUSTOMER_REST' ).

        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( lo_destination ).

        ASSERT lo_http_client IS BOUND.

        ro_odata_client_proxy = cl_web_odata_client_factory=>create_v2_remote_proxy(
                                            iv_service_definition_name = 'ZSCM_CUSTOMER'
                                            io_http_client             = lo_http_client
                                            iv_relative_service_root   = 'ZUI_BTPUSECASE001CUSTOMER' ).

      CATCH /iwbep/cx_cp_remote INTO DATA(lx_remote).
      CATCH /iwbep/cx_gateway INTO DATA(lx_gateway).
      CATCH cx_web_http_client_error INTO DATA(lx_web_http_client_error).
        RAISE SHORTDUMP lx_web_http_client_error.
    ENDTRY.
  ENDMETHOD.

  METHOD set_filter.
    "Request Filtering
    TRY.
        DATA(lt_filter) = request->get_filter( )->get_as_ranges( ).

        LOOP AT lt_filter ASSIGNING FIELD-SYMBOL(<fs_filter>).
          IF <fs_filter>-name = 'OPEN_ITEMS' OR
             <fs_filter>-name = 'IS_LOCKED'.
            " Raise exception. OPEN_ITEMS and IS_LOCKED cannot be filtered by the OData-Service, as those are coming from internal table.
          ENDIF.

          "Create filter factory for read request
          DATA(lo_filter_factory) = ch_read_request->create_filter_factory( ).

          DATA(lo_filter_for_current_field) = lo_filter_factory->create_by_range( iv_property_path = <fs_filter>-name
                                                                                  it_range         = <fs_filter>-range ).

          "Concatenate filter if more than one filter element
          DATA: lo_filter            TYPE REF TO /iwbep/if_cp_filter_node.
          IF lo_filter IS INITIAL.
            lo_filter = lo_filter_for_current_field.
          ELSE.
            lo_filter = lo_filter->and( lo_filter_for_current_field ).
          ENDIF.
        ENDLOOP.

        "Set filter
        IF lo_filter IS NOT INITIAL.
          ch_read_request->set_filter( lo_filter ).
        ENDIF.

      CATCH cx_rap_query_filter_no_range INTO DATA(lx_no_range).
      CATCH /iwbep/cx_gateway.
        "Handle exception
    ENDTRY.

  ENDMETHOD.

  METHOD enrich_data.
    DATA: lt_btpuc001 TYPE TABLE OF zbtpuc001.

    SELECT * FROM zbtpuc001 INTO TABLE @lt_btpuc001.

    LOOP AT business_data ASSIGNING FIELD-SYMBOL(<fs_data>).
      IF line_exists( lt_btpuc001[ customer =  <fs_data>-Customer ] ).
        <fs_data>-open_items = lt_btpuc001[ customer =  <fs_data>-Customer ]-open_items.
        <fs_data>-is_locked = lt_btpuc001[ customer =  <fs_data>-Customer ]-is_locked.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD update_credit_limit.
    " SAP Help - https://help.sap.com/docs/btp/sap-business-technology-platform/odata-request-update-entity
    DATA: ls_key TYPE STRUCTURE FOR ACTION IMPORT zbtp_hack_i_ce_customer\\customer~change_credit_limit.

    ls_key-%key-Customer = customer_id.

    TRY.
        "Instantiate Client Proxy
        zbtp_cl_hack_onprem_connect=>get_client_proxy( EXPORTING api_name = 'ZUI_BTPUSECASE001CUSTOMER'
                          IMPORTING ro_odata_client_proxy = DATA(lo_client_proxy) ).

        DATA(lo_upd_request) = lo_client_proxy->create_resource_for_entity_set( 'CUSTOMER' )->navigate_with_key( ls_key-%key )->create_request_for_update( /iwbep/if_cp_request_update=>gcs_update_semantic-patch ).
        DATA(customer_update) = VALUE zhack_customer(
            customer       = customer_id
            creditlimit    = creditlimit
        ).

        DATA(properties) = VALUE /iwbep/if_cp_runtime_types=>ty_t_property_path(
          ( `CREDITLIMIT` )
        ).
        lo_upd_request->set_business_data(
           is_business_data     = customer_update
           it_provided_property = properties
        ).

        lo_upd_request->execute( ).

      CATCH cx_http_dest_provider_error.
        "handle exception
      CATCH /iwbep/cx_gateway INTO DATA(lx_gateway).
        "handle exception
        DATA(lv_txt) = lx_gateway->get_text( ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
