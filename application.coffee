$(document).ready ->
    debug_count = 0

    if debugging
        $('body').append '<div id="debug"><h1>Debug</h1></div>'

    debug = (str) ->
        if debugging
            debug_count = debug_count + 1
            str = JSON.stringify str unless typeof str == 'string'
            $('#debug').append "<p>#{debug_count}: #{str}</p>"

    $('#ventures a, a#logo').each ->
        target_id = $(@).attr 'href'
        target = $ target_id
        others = $ ".page:not(#{target_id})"
        $(@).click ->
            others.attr 'hidden', true
            target.attr 'hidden', null

    gotoSlide = (num) ->
        num = confine num, 1, $('#slides .slide').size()
        $('.slide:not([hidden])').attr 'hidden', true
        $(".slide:nth-of-type(#{num})").attr 'hidden', null

    gotoPage = (name) ->
        $('.page:not([hidden])').attr 'hidden', true
        $("##{name}").attr 'hidden', null

    window.AppRoutes |= {}
    window.AppRoutes.slide = gotoSlide
    window.AppRoutes.page  = gotoPage
    window.AppRoutes.msg   = debug
    window.AppRoutes.debug = debug

    route = ({label, parcel}) -> window.AppRoutes[label] parcel

    # IMPORTANT: Do not change this function name (or the next
    # several lines) without adusting rake opts_update!
    phone_home = (count = 0) ->
        debug "Connection attempt #{count}"

        ws = new WebSocket 'ws://localhost:8080'

        ws.onmessage = (evt) -> route JSON.parse evt.data

        ws.onclose = ->
            debug 'socket closed'
            setTimeout((-> phone_home count + 1), 1000)

        ws.onopen = ->
            # Need to provide global access to the websocket...or maybe
            # don't open it by default and then provide global access to
            # phone_home.
            # Need to make this optional
            ws.send JSON.stringify
                label: 'subscription'
                parcel:
                    subscribe: ['iterable_demo']
            debug 'connected...'

    phone_home()
