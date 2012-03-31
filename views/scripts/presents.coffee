$ ->
    publish = (path, recipient, success) ->
        $.post '/' + recipient + '/presents', {path: path}, success

    fetch = (success) ->
        $.get '/presents', {}, success

    append = (magnet) ->
        $('.transfers').append '<div class="new-present incomplete">' + magnet.dn + '</div>'

    download = (magnets) ->
        if magnets.length > 0
            $.post '/presents', JSON.stringify magnets

    poll = ->
        appendAll = (magnets) ->
            magnets.forEach ((m) -> append m)

        gotMagnets = (magnets) ->
            appendAll magnets
            download magnets
            setTimeout poll, 1000

        fetch gotMagnets

    poll()

    $('#open').click ->
        path = $('#path').val()
        recipient = $('#recipient').val()

        publish path, recipient
