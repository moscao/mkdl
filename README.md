# Mario Kart 64 Deep Learning Bot

### big picture

The game environment of MarioKart 64 runs on the Bizhawk emulator which provides features for joypad support, recording functions of the gameplay as well as several debugging tools. Via Lua scripting it is possible to access and manipulate the game environment such that one can load and save the current state and subsequently take screenshots for learning abstract features of the environment.

In order to establish real time learning AI, we used a python server on which the lua environments connects to. The agent which acts on the environment is then soly implemented in python.

#### Youtube Videos

Check out our youtube videos!

<a href="http://www.youtube.com/watch?feature=player_embedded&v=tv8G5ks75To" target="_blank"><img src="http://img.youtube.com/vi/tv8G5ks75To/0.jpg" alt="Example video" width="240" height="180" border="10" /></a>

<a href="http://www.youtube.com/watch?feature=player_embedded&v=a89guwQpCB8" target="_blank"><img src="http://img.youtube.com/vi/a89guwQpCB8/0.jpg" alt="Example video" width="240" height="180" border="10" /></a>

#### simple random agent
To see how something works in a big picture an example is always pretty nice.
So here is an agent that executes random actions provided by the action space.

```python
from mario_env import MarioEnv

"""
Random agent. Executes random actions provided by the action space
"""
def main():
    # num_steering_dir divides the continuous steering direction into discrete action space of steering directions. Should be a odd number.
    # if jump = true the bot has the ability to jump, too
    env = MarioEnv(num_steering_dir=11, jump=False)

    # returns all possible actions that can be executed on the environment
    action_space = env.action_space

    # sets the agent back to start and returns current printscreen
    state = env.reset()
    done = False
    while not done:
        # samples some action uniformly from action space
        new_action = action_space.sample()
        # executes the action on the environment
        # returns new printscreen, current reward and if were done, info is empty
        new_state, reward, done, info  = env.step(new_action)

    # closes the bizhawk client and the socket
    env.close()

if __name__ == '__main__':
    main()
```

To get startet you can check out the simple [random action agent](https://github.com/SimiPro/mkdl/tree/master/mkdl/random_agent.py) which executes random actions.


#### interaction with bizhawk
Based on the gym environment from https://github.com/openai/gym. Each mario environment starts its own python server. Then we start via some environment variables who point to the bizhawk installation, the bizhawk client. For each environment which then reach out to the started python servers and connects on it. So we have an 1 to 1 sockets between mario environments on the python side and the mario clients on the bizhawk side. Via this socket we have a primitive text based communication with a few commands e.g. "RESET, 0.1234:1, ..".

The whole communication is basically encapsulated into the class MarioConnection and the agent only interacts with the MarioEnvironment. The MarioEnv implements the proposed Gym methods from openai:
- Reset -> State: Resets the environment and gets the initial status back.
- Act(action) -> State,Reward,Done: Executes an action and gets the reward back and if
 we're done or not.
- Close -> closes the environment
There would be some more methods possibly to use but we don't need them.
In our case the state is the current screenshot. The reward is some number in [0,1).

MarioConnection encapsulates the byte communication between bizhawk and python.



#### lua concerning side nodes

Since bizhawk can't currently accept some number to indicate which python server to connect. We had to create a script for each specific port to connect. This is the reason for the numerous new_mario_env0.lua, new_mario_env1.lua etc.
Since everything starts automatically.


#### bizhawk side notes
When bizhwak is loaded it loads the state saved on state 2. http://tasvideos.org/Bizhawk/SavestateFormat.html
You can save a state via: shift + F2 on 2.
Do this on the start of the track so the agent can directly start to cruse.

#### mkdl
mkdl holds all the python code.
Short summary:
* [random_agent.py](https://github.com/SimiPro/mkdl/tree/master/mkdl/random_agent.py): Example agent
* [start_bizhawk.py](https://github.com/SimiPro/mkdl/tree/master/mkdl/start_bizhawk.py) : responsible for starting bizhawk automatically
* [utils.py](https://github.com/SimiPro/mkdl/tree/master/mkdl/utils.py): some util functions
* [run_bizhawk.py](https://github.com/SimiPro/mkdl/tree/master/run_bizhawk.py): starts bizhawk from python console
* [policy.py](https://github.com/SimiPro/mkdl/tree/master/mkdl/policy.py): holds our used NeuralNetworks. Mostly used is OurCNN2 which is a CNN with 2 additional non-linear relu layers.
* [mario_env.py](https://github.com/SimiPro/mkdl/tree/master/mkdl/mario_env.py): holds the MarioEnv which the agent can act on. And also the MarioConnection which communicates with the Bizhawk
* [ppo2_agent.py](https://github.com/SimiPro/mkdl/tree/master/mkdl/ppo2_agent.py): executes the ppo agent. [openai ppo implementation](https://github.com/openai/baselines/tree/master/baselines/ppo2)
* [a2c_agent.py](https://github.com/SimiPro/mkdl/tree/master/mkdl/a2c_agent.py)
* [a3c_agent.py](https://github.com/SimiPro/mkdl/tree/master/mkdl/a3c_agent.py)
* just some additional agents we tried out and rejected again for our problem.

### Prerequisites

* windows only (thanks to bizhawk)
* python 3.6

## Installation

1. Install python 3.6.4 (https://www.python.org/downloads/release/python-364/)
2.  Install Pycharm https://www.jetbrains.com/pycharm/download/#section=windows
3. Open Pycharm and select the python interpreter we just installed in 1
4. Install package gym under File -> Project:mkdl -> Project Interpreter -> Green Plus symbol -> Add gym
5. (Only if you did not install pycharm) Try install gym via **pip install gym --no-dependencies**)
6. install tensorflow: **pip install tensorflow** (cpu version) / pip install tensorflow-gpu (gpu version)
7. install openai baselines but our extended ones:  **pip install --no-dependencies git+https://github.com/SimiPro/baselines.git**
8. install some more relevant module:
  * **pip install bench**
  * **pip install logger**
  * **pip install cloudpickle**
9. Install Microsoft MPI https://www.microsoft.com/en-us/download/details.aspx?id=55494
10. Install Bizhawk https://github.com/TASVideos/BizHawk/releases
11. Set the system environment variables:
  * BIZHAWK = "Path/To/BizHawkEmulator"
  * MKDL_LUA = "Path/To/MKDL_LUA/Folder"
12. Create folder "isos" in the Bizhawk Emulator folder and place the rom file ('mario.z64') in the folder

### Running

Before running environment we have to create a save state which is loaded when bizhawk is started. This is normally at the start line of a track. 
1. Run the Bizhawk  emulator and select the rom mario.z64
2. Choose Timetrial mode, choose a Player, choose a Kart and Track (e.g. Luigi Raceaway)
3. Press Shift + F1 to create a save state at slot 2, close the application
4. Run python random_agent.py


### Run the agent with pre trained weights 

How to use PPO2_agent.py

To run the agent with precomputed weights:
1. ppo2_agent.py, Line 103 change to run(..)
2. Go to site-packages -> baselines -> PPO2 -> ppo2.py -> Line 153 
Make sure load_path = "Path\To\Model\\Model_no"

The weights can be downloaded here and are thought to be used with the track of luigi raceaway: https://polybox.ethz.ch/index.php/s/FUgZ7cWQ7BVd2Kv


### Train the agent 

1. ppo2_agent.py, Line 103 change to train(..)
2. Go to site-packages -> baselines -> PPO2 -> ppo2.py -> Line 153 
Make sure load_path = None


## Contributing

* Simon Huber
* Huy Cao Tri Do
* Samuel Andermatt
* Quentin Auzepy


## License

This project is licensed under the MIT License

## Acknowledgments

* big thanks to https://github.com/rameshvarun/NeuralKart which was basically
our inspiration for doing this.
