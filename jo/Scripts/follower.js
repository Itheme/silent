if (typeof player === 'undefined') {
    player = { pos: { x: 0, y: 0 }}
}

function follower(object, params, timeDelta) {
    var dx = object.pos.x - player.pos.x
    var dy = object.pos.y - player.pos.y
    if (object.speedX == undefined) {
        object.speedX = 0;
        object.speedY = 0;
    }
    object.speedX -= dx * params.k
    object.speedY -= dy * params.k
    object.pos.x += object.speedX
    object.pos.y += object.speedY
    return object
}

module.exports = {
    follower: follower
}
