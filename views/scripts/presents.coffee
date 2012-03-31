class Presents
    publish: (path, recipient, success) ->
        $.post(
            "/" + recipient + "/presents",
            path: path,
            success: success
        )

$ ->
    $('#open').click ->
        path = $('#path').val()
        recipient = $('#recipient').val()

        p = new Presents
        p.publish path, recipient
