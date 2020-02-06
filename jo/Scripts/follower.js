function follower(object, params, timeDelta) {
    var dx = object.pos.x - player.pos.x
    var dy = object.pos.y - player.pos.y
    if (object.speedX == undefined) {
        oblect.speedX = 0;
        oblect.speedY = 0;
    }
    oblect.speedX -= dx * params.k
    oblect.speedY -= dy * params.k
    object.pos.x += oblect.speedX
    object.pos.y += oblect.speedY
    return object
}

module.exports = {
    follower: follower
}
