document.addEventListener('DOMContentLoaded', function() {
    initGame();
});

function getUserInfoFromURL() {
    const params = new URLSearchParams(window.location.search);
    return {
        userName: params.get('user'),
        nickname: params.get('nickname')
    };
}

function updateGreeting() {
    const userInfo = getUserInfoFromURL();
    if (userInfo.userName && userInfo.nickname) {
        document.getElementById('userGreeting').textContent = `Hi ${userInfo.nickname}, ready to play Animal Sounds Match Game!`;
    } else {
        document.getElementById('userGreeting').textContent = 'Welcome, ready to play Animal Sounds Match Game!';
    }
}

function initGame() {
    updateGreeting();
    const game = new Game();
    game.initBoard();
    attachResetHandlers(game);
}

class Game {
    constructor() {
        this.animals = [];
        this.cardChosen = [];
        this.cardChosenId = [];
        this.cardsWon = [];
        this.currentAudio = null;
        this.gameGrid = document.querySelector('.grid');  // Ensure this class exists in your HTML
    }

    initBoard() {
        this.loadAnimals();
        this.shuffleAnimals();
        this.renderCards();
    }

    loadAnimals() {
        this.animals = [
            { name: 'cat', img: 'cat.jpg', sound: 'cat.mp3' },
            { name: 'dog', img: 'dog.jpg', sound: 'dog.mp3' },
            { name: 'cow', img: 'cow.jpg', sound: 'cow.mp3' },
            { name: 'pig', img: 'pig.jpg', sound: 'pig.mp3' }
        ];
        this.animals = [...this.animals, ...this.animals]; // Duplicates for pairing
    }

    shuffleAnimals() {
        this.animals.sort(() => Math.random() - 0.5);
    }

    renderCards() {
        this.gameGrid.innerHTML = ''; // Clear previous cards
        this.animals.forEach((animal, index) => {
            let card = document.createElement('div');
            card.className = 'card'; // Ensure CSS styles this accordingly
            card.style.backgroundImage = `url('images/${animal.img}')`; // Adjust path if necessary
            card.addEventListener('click', () => this.flipCard(index));
            this.gameGrid.appendChild(card);
        });
    }

    flipCard(index) {
        let card = this.gameGrid.children[index];
        card.classList.add('flip');
        this.cardChosen.push(this.animals[index]);
        this.cardChosenId.push(index);
        if (this.cardChosen.length === 2) {
            setTimeout(() => this.checkForMatch(), 500);
        }
    }

    checkForMatch() {
        let cards = document.querySelectorAll('.card');
        let firstCard = cards[this.cardChosenId[0]];
        let secondCard = cards[this.cardChosenId[1]];
        if (this.cardChosen[0].name === this.cardChosen[1].name) {
            firstCard.removeEventListener('click', this.flipCard);
            secondCard.removeEventListener('click', this.flipCard);
            this.cardsWon.push(this.cardChosen[0]);
        } else {
            setTimeout(() => {
                firstCard.style.backgroundImage = 'url("images/card-back.jpg")'; // Reset to card back
                secondCard.style.backgroundImage = 'url("images/card-back.jpg")';
            }, 1000);
        }
        this.cardChosen = [];
        this.cardChosenId = [];
        if (this.cardsWon.length === this.animals.length / 2) {
            alert('Congratulations! You matched all the animals!');
        }
    }
}

function attachResetHandlers(game) {
    document.getElementById('reset-button').addEventListener('click', () => {
        game.initBoard();
    });
    document.getElementById('reset-sound-button').addEventListener('click', () => {
        if (game.currentAudio) {
            game.currentAudio.pause();
            game.currentAudio.currentTime = 0;
        }
    });
}
