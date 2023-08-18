CLASS zcl_btp_hackathon_test_ps DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_btp_hackathon_test_ps IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

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
