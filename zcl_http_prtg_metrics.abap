CLASS zcl_http_prtg_metrics DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES:
      BEGIN OF prtg_result,
        channel    TYPE c LENGTH 200,
        value      TYPE i,
        unit       TYPE c LENGTH 10,
        customunit TYPE c LENGTH 10,
      END OF prtg_result,
      prtg_results TYPE TABLE OF prtg_result WITH DEFAULT KEY,
      BEGIN OF prtg_response,
        text    TYPE c LENGTH 2000,
        error   TYPE i,
        results TYPE prtg_results,
      END OF prtg_response,
      BEGIN OF metrics_respone,
        prtg TYPE prtg_response,
      END OF metrics_respone.

    CLASS-METHODS:
      collect_results
        RETURNING
          VALUE(results) TYPE prtg_results
        EXCEPTIONS
          collect_error.

    INTERFACES:
      if_http_extension.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_http_prtg_metrics IMPLEMENTATION.
  METHOD if_http_extension~handle_request.
    if_http_extension~flow_rc = if_http_extension=>co_flow_ok_others_opt. " allow other extensions to do something

    DATA data TYPE metrics_respone.
    TRY.
        data = VALUE metrics_respone(
          prtg = VALUE prtg_response(
            text = 'OK'
            error = 0
            results = me->collect_results( ) ) ). " collect metrics from function modules
      CATCH cx_root INTO DATA(exception). " runtime will raise an exception cx_sy_no_handler
        data = VALUE metrics_respone(
            prtg = VALUE prtg_response(
              text = exception->get_text( )
              error = 1 ) ).
    ENDTRY.

    DATA(compress) = COND abap_bool( " compress the result if "pretty" header is missing
        WHEN server->request->get_header_field( name = 'pretty' ) IS INITIAL
        THEN abap_true
        ELSE abap_false ).
    DATA(json) = /ui2/cl_json=>serialize( " generate json
        data = data
        compress = compress
        pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

    server->response->set_header_field( " send response
      name  = 'Content-Type'
      value = 'application/json' ).
    server->response->set_header_field(
      name  = 'Expires'
      value = '0' ).
    server->response->set_cdata(
      data = json ).
  ENDMETHOD.

  METHOD collect_results.
    DATA uinfos TYPE STANDARD TABLE OF uinfo.
    CALL FUNCTION 'THUSRINFO' TABLES usr_tabl = uinfos EXCEPTIONS error_message = 1 OTHERS = 2.
    IF sy-subrc NE 0.
      RAISE collect_error.
    ENDIF.

    DATA bnames TYPE HASHED TABLE OF uinfo-bname WITH UNIQUE DEFAULT KEY.
    DATA tcodes TYPE HASHED TABLE OF uinfo-tcode WITH UNIQUE DEFAULT KEY.
    DATA terms TYPE HASHED TABLE OF uinfo-term WITH UNIQUE DEFAULT KEY.
    LOOP AT uinfos INTO DATA(uinfo).
      IF uinfo-bname IS NOT INITIAL.
        INSERT uinfo-bname INTO TABLE bnames.
      ENDIF.
      IF uinfo-tcode IS NOT INITIAL.
        INSERT uinfo-tcode INTO TABLE tcodes.
      ENDIF.
      IF uinfo-term IS NOT INITIAL.
        INSERT uinfo-term INTO TABLE terms.
      ENDIF.
    ENDLOOP.

    INSERT VALUE prtg_result( value = lines( bnames ) unit = 'Count' channel = 'Users' ) INTO TABLE results.
    INSERT VALUE prtg_result( value = lines( uinfos ) unit = 'Count' channel = 'Sessions' ) INTO TABLE results.
    INSERT VALUE prtg_result( value = lines( tcodes ) unit = 'Count' channel = 'Transactions' ) INTO TABLE results.
    INSERT VALUE prtg_result( value = lines( terms )  unit = 'Count' channel = 'Terminals' ) INTO TABLE results.
    FREE: uinfos, bnames, tcodes, terms.

    DATA cpus TYPE STANDARD TABLE OF cpu_all.
    CALL FUNCTION 'GET_CPU_ALL' TABLES tf_cpu_all = cpus EXCEPTIONS error_message = 1 OTHERS = 2.
    IF sy-subrc NE 0.
      RAISE collect_error.
    ENDIF.

    LOOP AT cpus INTO DATA(sum_cpu).
      AT LAST.
        SUM.
        INSERT VALUE prtg_result( value = sum_cpu-usr_total unit = 'CPU' channel = 'CPU utilization user' ) INTO TABLE results.
        INSERT VALUE prtg_result( value = sum_cpu-idle_true unit = 'CPU' channel = 'CPU utilization idle' ) INTO TABLE results.
        INSERT VALUE prtg_result( value = sum_cpu-sys_total unit = 'CPU' channel = 'CPU utilization system' ) INTO TABLE results.
        INSERT VALUE prtg_result( value = sum_cpu-wait_true unit = 'CPU' channel = 'CPU utilization IO wait' ) INTO TABLE results.
      ENDAT.
    ENDLOOP.
    FREE cpus.

    DATA mems TYPE STANDARD TABLE OF mem_all.
    CALL FUNCTION 'GET_MEM_ALL' TABLES tf_mem_all = mems EXCEPTIONS error_message = 1 OTHERS = 2.
    IF sy-subrc NE 0.
      RAISE collect_error.
    ENDIF.

    LOOP AT mems INTO DATA(sum_mem).
      AT LAST.
        SUM.
        INSERT VALUE prtg_result( value = sum_mem-phys_mem  customunit = 'Kb' channel = 'Physical memory conf' ) INTO TABLE results.
        INSERT VALUE prtg_result( value = sum_mem-free_mem  customunit = 'Kb' channel = 'Physical memory free' ) INTO TABLE results.
        INSERT VALUE prtg_result( value = sum_mem-swap_conf customunit = 'Kb' channel = 'Swap conf' ) INTO TABLE results.
        INSERT VALUE prtg_result( value = sum_mem-swap_free customunit = 'Kb' channel = 'swap free' ) INTO TABLE results.
      ENDAT.
    ENDLOOP.
    FREE mems.

    DATA lans TYPE STANDARD TABLE OF lan_single .
    CALL FUNCTION 'GET_LAN_SINGLE' TABLES tf_lan_single = lans EXCEPTIONS error_message = 1 OTHERS = 2.
    IF sy-subrc NE 0.
      RAISE collect_error.
    ENDIF.

    LOOP AT lans INTO DATA(sum_lan).
      AT LAST.
        SUM.
        INSERT VALUE prtg_result( value = sum_lan-in_packets unit = 'Count' channel = 'Lan packets in/s' ) INTO TABLE results.
        INSERT VALUE prtg_result( value = sum_lan-out_packet unit = 'Count' channel = 'Lan packets out/s' ) INTO TABLE results.
        INSERT VALUE prtg_result( value = sum_lan-in_errors  unit = 'Count' channel = 'Lan errors in/s' ) INTO TABLE results.
        INSERT VALUE prtg_result( value = sum_lan-out_errors unit = 'Count' channel = 'Lan errors out/s' ) INTO TABLE results.
      ENDAT.
    ENDLOOP.
    FREE lans.
  ENDMETHOD.
ENDCLASS.