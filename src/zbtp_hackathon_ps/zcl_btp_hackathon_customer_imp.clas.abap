CLASS zcl_btp_hackathon_customer_imp DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_btp_hackathon_customer_imp IMPLEMENTATION.


  METHOD if_rap_query_provider~select.

    DATA lt_result TYPE STANDARD TABLE OF zbtp_hackathon_ps_customer WITH NON-UNIQUE EMPTY KEY.


    DATA:
      lt_business_data TYPE TABLE OF zcustomer,
      lo_http_client   TYPE REF TO if_web_http_client,
      lo_client_proxy  TYPE REF TO /iwbep/if_cp_client_proxy,
      lo_request       TYPE REF TO /iwbep/if_cp_request_read_list,
      lo_response      TYPE REF TO /iwbep/if_cp_response_read_lst.

*DATA:
* lo_filter_factory   TYPE REF TO /iwbep/if_cp_filter_factory,
* lo_filter_node_1    TYPE REF TO /iwbep/if_cp_filter_node,
* lo_filter_node_2    TYPE REF TO /iwbep/if_cp_filter_node,
* lo_filter_node_root TYPE REF TO /iwbep/if_cp_filter_node,
* lt_range_CUSTOMER TYPE RANGE OF <element_name>,
* lt_range_UPDATE_MC TYPE RANGE OF abap_boolean.



    TRY.
        " Create http client
        DATA(lo_destination) = cl_http_destination_provider=>create_by_comm_arrangement(
                                                     comm_scenario  = 'ZBTP_CS_HACKATHON'
                                                     comm_system_id = 'DEVSBXD35'
                                                     service_id     = 'ZBTP_OS_CUSTOMER_REST' ).
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( lo_destination ).
        ASSERT lo_http_client IS BOUND.
        " If you like to use IF_HTTP_CLIENT you must use the following factory: /IWBEP/CL_CP_CLIENT_PROXY_FACT
        lo_client_proxy = cl_web_odata_client_factory=>create_v2_remote_proxy(

                                            iv_service_definition_name = 'ZBP_HACKATHON_CUSTOMER'

                                            io_http_client             = lo_http_client

                                            iv_relative_service_root   = 'ZUI_BTPUSECASE001CUSTOMER' ).


        " Navigate to the resource and create a request for the read operation
        lo_request = lo_client_proxy->create_resource_for_entity_set( 'CUSTOMER' )->create_request_for_read( ).


        IF io_request->is_total_numb_of_rec_requested( ).
          lo_request->request_count( ).
        ENDIF.

        IF io_request->is_data_requested( ).

          "Check if Paging is needed
          DATA(ls_paging) = io_request->get_paging( ).

          "Define $skip (if needed)
          IF ls_paging->get_offset( ) >= 0.

            lo_request->set_skip( ls_paging->get_offset( ) ).

          ENDIF.

          "Define $top (if needed)
          IF ls_paging->get_page_size( ) <> if_rap_query_paging=>page_size_unlimited.

            lo_request->set_top( ls_paging->get_page_size( ) ).

          ENDIF.




        ENDIF.


        " Create the filter tree
*lo_filter_factory = lo_request->create_filter_factory( ).
*
*lo_filter_node_1  = lo_filter_factory->create_by_range( iv_property_path     = 'CUSTOMER'
*                                                        it_range             = lt_range_CUSTOMER ).
*lo_filter_node_2  = lo_filter_factory->create_by_range( iv_property_path     = 'UPDATE_MC'
*                                                        it_range             = lt_range_UPDATE_MC ).

*lo_filter_node_root = lo_filter_node_1->and( lo_filter_node_2 ).
*lo_request->set_filter( lo_filter_node_root ).

        lo_request->set_top( 50 )->set_skip( 0 ).

        " Execute the request and retrieve the business data
        lo_response = lo_request->execute( ).
        lo_response->get_business_data( IMPORTING et_business_data = lt_business_data ).

        "Set Count

        " https://help.sap.com/docs/btp/sap-abap-restful-application-programming-model/implementing-data-and-count-retrieval?q=create_expand_node

        IF io_request->is_total_numb_of_rec_requested( ).

          io_response->set_total_number_of_records( lo_response->get_count( ) ).

        ENDIF.

        SELECT customer, open_items, is_locked
        FROM zbtpuc001
        FOR ALL ENTRIES IN @lt_business_data
        WHERE customer = @lt_business_data-Customer
        INTO TABLE @DATA(customer_db).

        LOOP AT lt_business_data REFERENCE INTO DATA(business_data).
          READ TABLE customer_db REFERENCE INTO DATA(cust_db)
            WITH KEY customer = business_data->Customer.
          IF sy-subrc = 0.
            APPEND CORRESPONDING #( business_data->* ) TO lt_result REFERENCE INTO DATA(result).
            result->OpenItems = cust_db->open_items.
            result->isLocked  = cust_db->is_locked.
          ENDIF.
        ENDLOOP.

        io_response->set_data( lt_result ).

      CATCH /iwbep/cx_cp_remote INTO DATA(lx_remote).
        " Handle remote Exception
        " It contains details about the problems of your http(s) connection

      CATCH /iwbep/cx_gateway INTO DATA(lx_gateway).
        " Handle Exception

      CATCH cx_web_http_client_error INTO DATA(lx_web_http_client_error).
        " Handle Exception
        RAISE SHORTDUMP lx_web_http_client_error.


    ENDTRY.




  ENDMETHOD.
ENDCLASS.
