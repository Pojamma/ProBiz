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
        // Ensure there is an element with the class "grid" in your HTML
        this.gameGrid = document.querySelector('.grid');
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
        // Duplicate the animals for matching pairs
        this.animals = [...this.animals, ...this.animals];
    }

    shuffleAnimals() {
        this.animals.sort(() => Math.random() - 0.5);
    }

    renderCards() {
        this.gameGrid.innerHTML = ''; // Clear previous cards
        this.animals.forEach((animal, index) => {
            let card = document.createElement('div');
            card.className = 'card'; // This class should be styled in your CSS
            card.style.backgroundImage = `url('images/${animal.img}')`;
            // Use an arrow function so that "this" refers to the Game instance
            card.addEventListener('click', () => this.flipCard(index));
            this.gameGrid.appendChild(card);
        });
    }

    flipCard(index) {
        // Prevent selecting the same card twice in a turn
        if (this.cardChosenId.includes(index)) return;
        
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
            // If it's a match, you might want to disable further clicks on these cards.
            // Note: Removing event listeners from inline arrow functions doesn’t work as expected,
            // so you could instead add a class (e.g., "matched") to prevent further interaction.
            firstCard.classList.add('matched');
            secondCard.classList.add('matched');
            this.cardsWon.push(this.cardChosen[0]);
        } else {
            setTimeout(() => {
                // Reset the card images to the card back and remove the flip effect
                firstCard.style.backgroundImage = 'url("images/card-back.jpg")';
                secondCard.style.backgroundImage = 'url("images/card-back.jpg")';
                firstCard.classList.remove('flip');
                secondCard.classList.remove('flip');
            }, 1000);
        }
        // Reset chosen cards for the next turn
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
