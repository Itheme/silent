function rolling(object, params, timeDelta) {
    if (object.angle !== undefined) {
        object.angle += params.speed;
    } else {
        object.angle = params.angle;
    }
    //console.log(JSON.stringify(object))
    if (object.angle > Math.PI*2.0) {
        object.angle -= Math.PI*2.0
    }
    object.pos.x = params.radius*Math.cos(object.angle)+params.originX
    object.pos.y = params.radius*Math.sin(object.angle)+params.originY
    return object
}

module.exports = {
    rolling: rolling
}
