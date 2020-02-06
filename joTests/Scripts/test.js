'use strict'
const assert = require('assert');

const { rolling } = require('../../jo/Scripts/rolling.js')

describe('Scripts', function() {
    describe('rolling', function () {
        var object = null
        const params = { angle: 1.0, speed: 0.1, radius: 5.0, originX: 2.0, originY: 3.0 }
        beforeEach(function () {
            object = { id: 'test', pos: { x: 0, y: 0} }
        })
        it('returns same object', function() {
            assert.equal(rolling(object, params, 3), object)
        })
        it('assigns angle', function() {
            rolling(object, params, 3)
            assert.equal(object.angle, params.angle)
        })
        it('rolls', function() {
            object.angle = -1
            rolling(object, params, 3)
            assert.equal(object.angle, -1 + params.speed)
            assert.equal(object.pos.x, 5.108049841353322)
            assert.equal(object.pos.y, -0.916634548137417)
        })
    })
})
