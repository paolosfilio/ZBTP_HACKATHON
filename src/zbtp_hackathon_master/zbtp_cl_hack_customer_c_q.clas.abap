CLASS zbtp_cl_hack_customer_c_q DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zbtp_cl_hack_customer_c_q IMPLEMENTATION.
  METHOD if_rap_query_provider~select.

    DATA: lt_business_data TYPE TABLE OF zhack_customer,
          lt_I_CE_CUSTOMER TYPE TABLE OF zbtp_hack_i_ce_customer.

    TRY.
        "Instantiate Client Proxy
        zbtp_cl_hack_onprem_connect=>get_client_proxy( EXPORTING api_name = 'ZUI_BTPUSECASE001CUSTOMER'
                                                   IMPORTING ro_odata_client_proxy = DATA(lo_client_proxy) ).

        "Create Read Request
        DATA(lo_read_request) = lo_client_proxy->create_resource_for_entity_set( 'CUSTOMER' )->create_request_for_read( ).

        "SAP Help - https://help.sap.com/docs/btp/sap-abap-restful-application-programming-model/implementing-data-and-count-retrieval
        "Request Count
        IF io_request->is_total_numb_of_rec_requested( ).
          lo_read_request->request_count( ).
        ENDIF.

        "Check whether data is requested
        IF io_request->is_data_requested( ).

          "Check if Paging is needed
          DATA(ls_paging) = io_request->get_paging( ).
          "Define $skip (if needed)
          IF ls_paging->get_offset( ) >= 0.
            lo_read_request->set_skip( ls_paging->get_offset( ) ).
          ENDIF.
          "Define $top (if needed)
          IF ls_paging->get_page_size( ) <> if_rap_query_paging=>page_size_unlimited.
            lo_read_request->set_top( ls_paging->get_page_size( ) ).
          ENDIF.

          "SAP Help - https://help.sap.com/docs/btp/sap-abap-restful-application-programming-model/implementing-filtering
          "Set filter
          zbtp_cl_hack_onprem_connect=>set_filter( EXPORTING request = io_request
                                                     CHANGING ch_read_request = lo_read_request ).

          "Execute the Request
          DATA(lo_response) = lo_read_request->execute( ).

          "Set Count
          " https://help.sap.com/docs/btp/sap-abap-restful-application-programming-model/implementing-data-and-count-retrieval
          IF io_request->is_total_numb_of_rec_requested( ).
            io_response->set_total_number_of_records( lo_response->get_count( ) ).
          ENDIF.

          lo_response->get_business_data( IMPORTING et_business_data = lt_business_data ).

          lt_I_CE_CUSTOMER = CORRESPONDING #( lt_business_data ).

          "Enrich business data (with zbtpuc001)
          zbtp_cl_hack_onprem_connect=>enrich_data( CHANGING business_data = lt_I_CE_CUSTOMER ).

          io_response->set_data( lt_I_CE_CUSTOMER ).

        ENDIF.

      CATCH /iwbep/cx_gateway.
        "handle exception
      CATCH cx_http_dest_provider_error.
        "handle exception
    ENDTRY.

  ENDMETHOD.
ENDCLASS.
