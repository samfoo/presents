$ ->
    publish = (path, recipient, success) ->
        $.post '/' + recipient + '/presents', {path: path}, success

    fetch = (success) ->
        $.get '/presents', {}, success

    append = (magnet) ->
        $('.transfers').append '<div class="new-present incomplete">' + magnet.dn + '</div>'

    poll = ->
        appendAll = (magnets) ->
            magnets.forEach ((m) -> append m)

        fetch ((d) -> appendAll d; setTimeout poll, 1000)

    poll()

    $('#open').click ->
        path = $('#path').val()
        recipient = $('#recipient').val()

        publish path, recipient
