**What is AI**

- Ability to Reason
- The ability to represent knowledge about the world and unerstand there are certain intitile
- Planning 
- Communicate

**12 Types of Problems AI is trying to Solve**

- From slides

**How do you define Machine Learning**

- Provide Weight and Models and you get output
- Provide in inputs, and output -> AI figures out how to get there
- From Slides -> What is machine learning
- Gives you results based on Probablilty 


**Algorithmes: Classifiers**

- Nearest Neighbors
- Lieanr SVM 
- Desition Tree
- Naive Bayes

**Tribes of Machine Learning**

- From Slides, review  the favored algorithms at bottom of slides

**Phases of Evolution**

- From slides, review Server Architecutre
- Try and predict future AI Server architecutres

**Machine Learning Cheat Sheet**

![](/Users/isaackkaranja/Dropbox/Screenshots/Screenshot 2017-10-28 09.55.04.png)

##**Neuron Model**

**Activation Functions**

- sigmoid
- tanh
- ReLU

Layers = Number of neurons, increase the accuracy and amount of computing is rquired


**What is a Neuro Network youtube Video**

- Good Explation of how everything builds out

<iframe width="854" height="480" src="https://www.youtube.com/embed/aircAruvnKk" frameborder="0" gesture="media" allowfullscreen></iframe>

- 3D visulation, first part of the video is old technique, last part of video is new technique

<iframe width="854" height="480" src="https://www.youtube.com/embed/3JQ3hYko51Y" frameborder="0" gesture="media" allowfullscreen></iframe>

- Visiualize with editing how neurons interact with each other

![http://playground.tensorflow.org](http://playground.tensorflow.org)


**Stanford Layout of Hidden Layer**

http://cs.stanford.edu/people/karpathy/convnetjs/

- Increasing Neuaal Network size over time
- BigDL - Paper in 2010 -> Leading to advent of SIRI, Alexa


**Neural Network 24 Adjustments**

- From Slides
- Architecture
- Hyper Paramenter Tuning


**Tools**

- Theano
- Caffe
- Caffe/Caffe2
- Microsfot CNTK
- Pytourch
- Kranis


Develop in any tool, deploy in GlueOn
- Symbolic on deveoping
- Deploying in Gnluon

**Languages and Capaibilities**

- From Slides


**Activation Functions**

- RLU,Does not converge in one layer, unlinke 

**Optimization Functions**

- Subustian RUder 

**Explanation on overfitting**
https://cloud.google.com/blog/big-data/2017/01/learn-tensorflow-and-deep-learning-without-a-phd
 - youtube video on test and training
 - As you overfit, errors start going up
 - Drop out - is watching the learning rate then as errors start increasing you need to stop learning
 	- You assign a dropout rate
 	- Stopping rule, assigns when to stop dropping 
 	- you can assign drop off to different layers, hidden layers, input layer, output layer
 	- Epoc - pass through the machine learning 
 	- Dropout Technique - in each EPOC, a % of weights no not get evaluated as oyou move from one layer to the next

**Machine Learning**
**DataScient in Machine Learning 90% of time is to define**
**Different Algorithms willl be selected based on your determination of the classification**


- Supervised
	- Classification 
	- Regression (error function, absolute value)
- Unsupervisded
	- Clustering - example gene expression data
	- Anamoly Detection	
- Reinforcement Learning


**Different Fuctions to get output**

- Neuro Networks, SVM - Support Vector Machines
	- Biggest issue with SVM, you cannnot explanin the layers
- Additive Functions
- Linear Functions
- Nearest Neighbor Model 







**Day 2 Training**

- Site with Hardware accelerated Machine Libraries [https://deeplearnjs.org/](https://deeplearnjs.org/)
- Site that you can train machine: [https://teachablemachine.withgoogle.com/](https://teachablemachine.withgoogle.com/)
- Using RNN in google translate - history [Medium.com - google translate](https://medium.com/@ageitgey/machine-learning-is-fun-part-5-language-translation-with-deep-learning-and-the-magic-of-sequences-2ace0acca0aa)
- Using RNN for facial recognition [Medium.com - google images](https://medium.com/@ageitgey/machine-learning-is-fun-part-4-modern-face-recognition-with-deep-learning-c3cffc121d78)
- Read about encoding of images, videos, words
- Word embedding - how encoding - vectors - [Word Embedding](http://ronxin.github.io/wevi/)
- Word Embeding - text encoding with vectors [Word Embedding - tensorflow](http://projector.tensorflow.org/)



**CLoud Provider API**

- Amazon - MXNET (Canege Mellon) - Gluon
- Facebook - Torche & Caffe (Flexible but loww to run)
- Google - Tensorflow
- IBM - Watson 



- Tensorflow - Keras
- theano - Keras



**Resources for learning*

- [150 great resources for Deep Learning](https://unsupervisedmethods.com/over-150-of-the-best-machine-learning-nlp-and-python-tutorials-ive-found-ffce2939bd78)



JYNPER NOTEBOOKS
- deep-learning-master/sentiment-rnn/Sentiment_RNN_Solution.ipynb
- deep-learning-master/sentiment-rnn/Sentiment_RNN_Solution.ipynb
- deep-learning-master/gan_mnist/Intro_to_GANs_Exercises.ipynb
- deep-learning-master/gan_mnist/Intro_to_GANs_Solution.ipynb


Training on Floyd
- https://www.floydhub.com/
- Dr Kapathi - CS231 - Community AMI, Bitfusion - AMI



 
Spacy
https://www.analyticsvidhya.com/blog/2017/04/natural-language-processing-made-easy-using-spacy-%E2%80%8Bin-python/

Google Translate RNN
https://medium.com/@ageitgey/machine-learning-is-fun-part-5-language-translation-with-deep-learning-and-the-magic-of-sequences-2ace0acca0aa

Chatbots
https://medium.com/towards-data-science/personality-for-your-chatbot-with-recurrent-neural-networks-2038f7f34636

[RNN Chatbot Reditt](https://github.com/pender/chatbot-rnn)

RNN Chatbot Movie Database
https://github.com/musca1997/cornell-movie-chatbot






**Pepare the Data**
- Review Standaiziation vs NOrmalization for machine learning


**ChatBot - NLP**
- Email, look at topics at the end of file
	Easy installation
	Python API
	Multi Language support
	Tokenization
	Part-of-speech tagging
	Sentence segmentation
	Dependency parsing
	Entity Recognition
	Integrated word vectors	
	Sentiment analysis
	Coreference resolution




Instructors

bhairavm@gmail.com
eduraka123
https://www.edureka.co/my-course/ai-deep-learning-with-tensorflow

ravi.ilango@gmail.com
































Use Keras for Training, then convert this to 





cs2-stanford AMI


Example 1: Facial recongintion _CNN and NeuralNet
tree/awslabs/facereg


Example 2: Hello World
tree/awslabs/mnist













Model 
- pickle
- TUli 


To Review


- Sigmoid Functions
- ReLU


Lasanea
Theanos
Keras
- Backend can be tensor flow
- Higher level machine elarning package


http://cs231n.github.io/aws-tutorial/ 

Class Stanford Class

