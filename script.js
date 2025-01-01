// İlişki türleri
const RELATIONS = {
    'best_friend': {
        title: '👑 En İyi Arkadaş',
        header: 'Canım Dostum',
        note: 'Seninle geçirdiğimiz her an çok değerli. 2025\'te dostluğumuz daha da güçlensin! Bu hediyeyi özenle senin için seçtim.',
        style: 'from-purple-500 to-pink-500'
    },
    'close_friend': {
        title: '💫 Yakın Arkadaş',
        header: 'Değerli Arkadaşım',
        note: 'Arkadaşlığımız benim için çok kıymetli. 2025\'in sana tüm güzellikleri getirmesini diliyorum!',
        style: 'from-blue-500 to-indigo-500'
    },
    'work_friend': {
        title: '💼 İş Arkadaşı',
        header: 'Sevgili İş Arkadaşım',
        note: 'Birlikte çalışmaktan keyif aldığım değerli iş arkadaşım. 2025\'te kariyerinde nice başarılara!',
        style: 'from-green-500 to-teal-500'
    },
    'family': {
        title: '❤️ Aile Üyesi',
        header: 'Canım Ailem',
        note: 'Ailemizin değerli üyesi. 2025 senin için sağlık, mutluluk ve başarı getirsin!',
        style: 'from-red-500 to-pink-500'
    },
    'relative': {
        title: '🌟 Akraba',
        header: 'Sevgili Akrabam',
        note: '2025\'in sana ve ailene mutluluk, sağlık ve başarı getirmesini diliyorum.',
        style: 'from-yellow-500 to-orange-500'
    },
    'teacher': {
        title: '📚 Öğretmenim',
        header: 'Değerli Öğretmenim',
        note: 'Bana kattığınız her şey için teşekkür ederim. 2025 size sağlık ve mutluluk getirsin!',
        style: 'from-cyan-500 to-blue-500'
    },
    'student': {
        title: '🎓 Öğrencim',
        header: 'Sevgili Öğrencim',
        note: 'Başarılarınla gurur duyuyorum. 2025\'te tüm hedeflerine ulaşmanı diliyorum!',
        style: 'from-emerald-500 to-green-500'
    },
    'mentor': {
        title: '🌠 Mentorum',
        header: 'Değerli Mentorum',
        note: 'Yol göstericiliğiniz için minnettarım. 2025 size güzellikler getirsin!',
        style: 'from-violet-500 to-purple-500'
    },
    'custom': {
        title: '✨ Özel',
        header: 'Özel Not',
        note: '',
        style: 'from-gray-500 to-blue-500'
    }
};

// Hediye türleri
const GIFTS = {
    'artist': {
        title: '🎨 Sanatçı Hediyesi',
        items: [
            '✨ Sınırsız renk paleti',
            '🖌️ İlham veren fırçalar',
            '🎭 Yaratıcılık beresi',
            '🖼️ Sergi fırsatı',
            '🌈 Renk ustası sertifikası'
        ]
    },
    'musician': {
        title: '🎵 Müzisyen Hediyesi',
        items: [
            '🎼 Beste yapan sihirli kalem',
            '🎸 Her enstrümana dönüşen tel',
            '🎧 Müzik perisi kulaklıklar',
            '🎹 Cep stüdyosu',
            '🎶 Melodi yakalayıcı'
        ]
    },
    'tech': {
        title: '💻 Teknoloji Hediyesi',
        items: [
            '⌨️ Kod yazan sihirli klavye',
            '🖥️ Hata düzeltici gözlük',
            '📱 Fikir geliştirici tablet',
            '🤖 AI asistan',
            '🔮 Bug bulucu kristal küre'
        ]
    },
    // Diğer hediye tipleri...
};

// Ana fonksiyonlar
function updateRelationDetails() {
    const type = document.getElementById('relationType').value;
    const relation = RELATIONS[type];
    
    document.getElementById('customHeader').value = relation.header;
    document.getElementById('personalNote').value = relation.note;
    
    updatePreview();
}

function resetHeader() {
    const type = document.getElementById('relationType').value;
    document.getElementById('customHeader').value = RELATIONS[type].header;
}

function resetNote() {
    const type = document.getElementById('relationType').value;
    document.getElementById('personalNote').value = RELATIONS[type].note;
}

function updatePreview() {
    const name = document.getElementById('friendName').value || '[İsim]';
    const header = document.getElementById('customHeader').value;
    const type = document.getElementById('giftType').value;
    const note = document.getElementById('personalNote').value;
    const relation = RELATIONS[document.getElementById('relationType').value];
    const gift = GIFTS[type];

    document.getElementById('preview').innerHTML = `
        <div class="space-y-6">
            <div class="p-4 rounded-lg bg-opacity-20 backdrop-blur-sm border border-white border-opacity-10">
                <h4 class="text-xl font-bold mb-2">${header} ${name}</h4>
                <p class="text-gray-300">${note}</p>
            </div>
            
            <div class="p-4 rounded-lg bg-gradient-to-r ${relation.style} bg-opacity-20">
                <h4 class="text-xl font-bold mb-2">${gift.title}</h4>
                <div class="space-y-2">
                    ${gift.items.map(item => `
                        <div class="flex items-center gap-2">
                            <span>${item}</span>
                        </div>
                    `).join('')}
                </div>
            </div>
        </div>
    `;
}

function generateLink() {
    const name = document.getElementById('friendName').value;
    const type = document.getElementById('giftType').value;
    const header = document.getElementById('customHeader').value;
    const note = document.getElementById('personalNote').value;
    const relationType = document.getElementById('relationType').value;

    if (!name) {
        alert('Lütfen bir isim girin!');
        return;
    }

    const params = new URLSearchParams({
        name: name,
        type: type,
        header: header,
        note: note,
        relation: relationType
    });

    const link = `https://evleviyet.github.io/happy-new-year/gift.html?${params.toString()}`;
    
    document.getElementById('generatedLink').value = link;
    document.getElementById('linkResult').classList.remove('hidden');

    saveLink({
        id: Date.now(),
        name: name,
        type: type,
        header: header,
        link: link,
        date: new Date().toLocaleDateString()
    });
}

function saveLink(linkData) {
    const savedLinks = JSON.parse(localStorage.getItem('savedLinks') || '[]');
    savedLinks.unshift(linkData);
    localStorage.setItem('savedLinks', JSON.stringify(savedLinks));
    updateSavedLinks();
}

function updateSavedLinks() {
    const savedLinks = JSON.parse(localStorage.getItem('savedLinks') || '[]');
    const container = document.getElementById('savedLinks');

    if (savedLinks.length === 0) {
        container.innerHTML = '';
        return;
    }

    container.innerHTML = `
        <h3 class="text-xl text-blue-300 mb-4">Kaydedilen Linkler</h3>
        <div class="space-y-3">
            ${savedLinks.map(link => `
                <div class="cyber-box p-4 rounded-lg flex justify-between items-center">
                    <div>
                        <div class="font-bold text-white">${link.name}</div>
                        <div class="text-sm text-gray-400">${link.header} - ${link.date}</div>
                    </div>
                    <div class="flex gap-2">
                        <button onclick="window.open('${link.link}', '_blank')" 
                                class="bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 rounded text-sm">
                            Aç
                        </button>
                        <button onclick="window.open('${link.link}&test=true', '_blank')" 
                                class="bg-green-600 hover:bg-green-700 text-white px-3 py-1 rounded text-sm">
                            Test
                        </button>
                        <button onclick="deleteLink(${link.id})" 
                                class="bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded text-sm">
                            Sil
                        </button>
                    </div>
                </div>
            `).join('')}
        </div>
    `;
}

function deleteLink(id) {
    if (confirm('Bu linki silmek istediğinizden emin misiniz?')) {
        const savedLinks = JSON.parse(localStorage.getItem('savedLinks') || '[]');
        const filteredLinks = savedLinks.filter(link => link.id !== id);
        localStorage.setItem('savedLinks', JSON.stringify(filteredLinks));
        updateSavedLinks();
    }
}

function copyLink() {
    const linkInput = document.getElementById('generatedLink');
    linkInput.select();
    document.execCommand('copy');
    
    const copyButton = event.target;
    copyButton.textContent = '✅ Kopyalandı!';
    setTimeout(() => {
        copyButton.textContent = '📋 Kopyala';
    }, 2000);
}

function testLink() {
    const link = document.getElementById('generatedLink').value;
    if (link) {
        window.open(link + '&test=true', '_blank');
    }
}

// Sayfa yüklendiğinde
window.onload = function() {
    updateRelationDetails();
    updateSavedLinks();
};
