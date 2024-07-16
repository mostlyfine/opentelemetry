import os
import requests
import logging
from random import randint
from flask import Flask, request

import pyroscope
from opentelemetry import metrics

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

pyroscope.configure(
    application_name="sample-app",
    server_address=os.getenv("PYROSCOPE_SERVER_ADDRESS"),
    enable_logging=True,
)

meter = metrics.get_meter(__name__)
dice_count = meter.create_gauge("dice_count")


@app.route("/")
@app.route("/rolldice")
def roll_dice():
    player = request.args.get('player', default=None, type=str)
    result = roll()
    dice_count.set(result)
    if result == 7:     # Generate Error
        result = 100 / 0
    if player:
        logger.warning("%s is rolling the dice: %d", player, result)
    else:
        logger.warning("Anonymous player is rolling the dice: %d", result)
    return str(result)


@app.route("/weather/")
@app.route("/weather/<int:area>")
def weather(area=130000):
    jma_url = f'https://www.jma.go.jp/bosai/forecast/data/forecast/{area}.json'
    jma_json = requests.get(jma_url).json()
    jma_weather = jma_json[0]["timeSeries"][0]["areas"][0]["weathers"][0]
    logger.info(jma_weather)
    return jma_weather


def roll():
    return randint(1, 7)


def work(n):
    i = 0
    while i < n:
        i += 1


@app.route("/fast")
def fast_function():
    with pyroscope.tag_wrapper({"function": "fast"}):
        work(20000)
    return "OK"


@app.route("/slow")
def slow_function():
    with pyroscope.tag_wrapper({"function": "slow"}):
        work(80000)
    return "OK"


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5002)
