const fs = require('fs');
const { exec } = require('child_process');
const ProgressBar = require('progress');

// Charger les URLs depuis un fichier texte
const inputFile = './urls.txt'; // Chemin vers votre fichier d'URLs

// Lire les URLs depuis le fichier
const videoUrls = fs.readFileSync(inputFile, 'utf-8').split('\n').filter(Boolean);

const outputDir = './downloads';

if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir);
}

const downloadVideo = (url) => {
    console.log(`Téléchargement de la vidéo : ${url}`);

    const filename = url.split('=')[1]; // Utilisation de l'ID de la vidéo pour nommer le fichier

    // Commande pour télécharger la vidéo et convertir en MP3
    const command = `yt-dlp -x --audio-format mp3 -o "${outputDir}/%(title)s.%(ext)s" ${url}`;

    // Créer une barre de progression avec les bonnes options
    const bar = new ProgressBar(':bar :percent :etas', {
        total: 100,
        width: 40,
        complete: '=',
        incomplete: ' ',
        renderThrottle: 100,
        clear: true
    });

    // Exécution de la commande yt-dlp
    const child = exec(command, (error, stdout, stderr) => {
        if (error) {
            console.error(`Erreur lors du téléchargement de ${url}: ${error.message}`);
            return;
        }
        if (stderr) {
            console.error(`Erreur stderr: ${stderr}`);
            return;
        }
        console.log(`Téléchargement terminé pour ${url}`);
    });

    // Mettre à jour la barre de progression avec les données de téléchargement
    child.stdout.on('data', (data) => {
        if (data.includes('MB / MB')) {
            // Extraire la progression du téléchargement
            const matches = data.match(/(\d+)%/);
            if (matches) {
                bar.update(parseInt(matches[1]) / 100);
            }
        }
    });
};

// Télécharger toutes les vidéos de la liste
videoUrls.forEach(url => downloadVideo(url));

