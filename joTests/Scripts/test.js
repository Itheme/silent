'use strict'
const assert = require('assert');

const { rolling } = require('../../jo/Scripts/rolling.js')
const { follower } = require('../../jo/Scripts/follower.js')

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
    describe('follower', function () {
        var object = null
        const params = { k: 2.0 }
        var player = {pos: {}}
        beforeEach(function () {
            object = { id: 'test', pos: { x: 0, y: 0} }
        })
        it('stays', function() {
            follower(object, params, 3)
            assert.equal(object.pos.x, 0)
            assert.equal(object.pos.y, 0)
            assert.equal(object.speedX, 0)
            assert.equal(object.speedY, 0)
        })
        it('starts', function() {
            object.pos.x = -1
            object.pos.y = 1
            follower(object, params, 3)
            assert.equal(object.speedX, 2)
            assert.equal(object.speedY, -2)
        })
        it('follows', function() {
            object.pos.x = -1
            object.pos.y = 1
            object.speedX = -1
            object.speedY = 1
            follower(object, params, 3)
            assert.equal(object.speedX, 1)
            assert.equal(object.speedY, -1)
        })
    })
})
