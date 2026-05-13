/**
 * ==================================================
 * INTERACTIVE DYNAMIC ENGINE FOR MUSCLES UP GYM
 * ==================================================
 */

document.addEventListener('DOMContentLoaded', () => {
  // Sync Footer Current Year
  const yearSpan = document.getElementById('currentYear');
  if (yearSpan) {
    yearSpan.textContent = new Date().getFullYear();
  }

  // Fetch dynamic configurations from backend database on load
  fetchWebsiteConfig();

  // Attach submit handler to Lead inquiry form
  const leadForm = document.getElementById('leadInquiryForm');
  if (leadForm) {
    leadForm.addEventListener('submit', handleFormSubmit);
  }
});

// Default Fallback Photos
const DEFAULT_GALLERY = [
  'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?q=80&w=600',
  'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=600',
  'https://images.unsplash.com/photo-1518310383802-640c2de311b2?q=80&w=600'
];

/**
 * Fetch All Website Configurations Live from SQLite
 */
async function fetchWebsiteConfig() {
  try {
    const response = await fetch('/api/website');
    if (!response.ok) {
      throw new Error('Could not pull website parameters.');
    }
    const config = await response.json();
    
    // 1. Set Announcement Marquee Text & Visibility
    renderAnnouncement(config.announcement);

    // 2. Set Counter Statistics Dashboard
    renderStats(config.stats);

    // 3. Render dynamic Pricing Plan Cards & Dropdown Option List
    renderPlansAndPricing(config.plans);

    // 4. Set Video Clips Highlight Reels (with Embed conversions)
    renderVideos(config.videos);

    // 5. Render Photo Gallery GRID (Base64 uploads)
    renderGallery(config.gallery);

    // 6. Set Gym Contact Details
    renderContactDetails(config.contact);

  } catch (err) {
    console.error('🔴 Fetching layout settings failed, loading offline states:', err);
    // Offline / Network fail fallback
    renderAnnouncement(null);
    renderStats(null);
    renderPlansAndPricing([]);
  }
}

/**
 * 1. Render Announcement Bar
 */
function renderAnnouncement(announcement) {
  const bar = document.getElementById('announcementBar');
  const scroller = document.getElementById('announcementText');
  
  if (!bar || !scroller) return;

  if (announcement && announcement.show && announcement.text && announcement.text.trim()) {
    scroller.textContent = announcement.text;
    bar.classList.remove('hidden');
  } else {
    bar.classList.add('hidden');
  }
}

/**
 * 2. Render Counter Statistics Dashboard
 */
function renderStats(stats) {
  const membersNode = document.getElementById('statMembers');
  const coachesNode = document.getElementById('statTrainers');
  const yearsNode = document.getElementById('statYears');

  if (stats) {
    if (membersNode) membersNode.textContent = stats.membersTrained || '1,000+';
    if (coachesNode) coachesNode.textContent = stats.certifiedTrainers || '8+';
    if (yearsNode) yearsNode.textContent = stats.yearsExp || '4+';
  }
}

/**
 * 3. Render dynamic Pricing Plan Cards & Dropdown Option List
 */
function renderPlansAndPricing(plans) {
  const plansGrid = document.getElementById('plansGrid');
  const packageSelect = document.getElementById('formPackage');
  
  if (!plansGrid) return;
  plansGrid.innerHTML = ''; // Clear loaders

  // Clear existing options, keep the disabled placeholder
  if (packageSelect) {
    packageSelect.innerHTML = '<option value="" disabled selected>Select your package...</option>';
  }

  // Local Default fallback plans if SQLite is empty
  const activePlans = (plans && plans.length > 0) ? plans : [
    {
      name: "MONTHLY CARDIO & WEIGHTS",
      price: "₹1,500",
      period: "/month",
      features: ["Access to Weight Floor", "Free Locker Access", "General Trainer Guidance"],
      badge: "Standard",
      isFeatured: false
    },
    {
      name: "6-MONTHS PRO-FITNESS",
      price: "₹7,500",
      period: "/6 months",
      features: ["All Weight Floor access", "Free locker & showers", "2 Free body scans", "Personalized Workout Draft"],
      badge: "Best Value",
      isFeatured: true
    },
    {
      name: "1-YEAR VIP MUSCLE UP",
      price: "₹12,000",
      period: "/year",
      features: ["24/7 Premium Gym Access", "Free locker, steam & sauna", "Monthly Dietitian checks", "1 Personal Coach slot"],
      badge: "Premium Choice",
      isFeatured: false
    }
  ];

  activePlans.forEach(plan => {
    // A. Generate Pricing Cards
    const card = document.createElement('div');
    card.className = `plan-card ${plan.isFeatured ? 'featured' : ''}`;

    let badgeHtml = '';
    if (plan.badge && plan.badge.trim() !== '') {
      badgeHtml = `<span class="plan-badge">${plan.badge}</span>`;
    }

    let featuresListHtml = '';
    const feats = (plan.features && plan.features.length > 0) 
      ? plan.features 
      : ["Full floor access", "Locker room facilities"];

    feats.forEach(feat => {
      featuresListHtml += `<li><span class="plan-check">✓</span> ${feat}</li>`;
    });

    card.innerHTML = `
      ${badgeHtml}
      <div>
        <h3 class="plan-name">${plan.name}</h3>
        <div class="plan-rate-box">
          <span class="plan-price">${plan.price}</span>
          <span class="plan-period">${plan.period || '/month'}</span>
        </div>
        <hr class="plan-divider">
        <ul class="plan-features">
          ${featuresListHtml}
        </ul>
      </div>
      <button class="btn-select-plan" onclick="handleSelectPlanCallback('${encodeURIComponent(plan.name)}')">
        SELECT THIS PLAN
      </button>
    `;
    plansGrid.appendChild(card);

    // B. Generate Select Option Items
    if (packageSelect) {
      const option = document.createElement('option');
      option.value = plan.name;
      option.textContent = plan.name;
      packageSelect.appendChild(option);
    }
  });
}

/**
 * Callback on clicking "SELECT THIS PLAN" card
 */
window.handleSelectPlanCallback = (encodedPlanName) => {
  const planName = decodeURIComponent(encodedPlanName);
  
  const packageSelect = document.getElementById('formPackage');
  if (packageSelect) {
    packageSelect.value = planName;
  }

  // Smooth scroll to Inquiry form
  const contactSection = document.getElementById('contact-section');
  if (contactSection) {
    contactSection.scrollIntoView({ behavior: 'smooth' });
  }

  showToastNotification(`Selected ${planName}! Complete your contact form below.`, '⚡');
};

/**
 * 4. Set Video Clips Highlight Reels (with Embed conversions)
 */
function renderVideos(videos) {
  const vSection = document.getElementById('videos-section');
  const vGrid = document.getElementById('videosGrid');
  const navLink = document.getElementById('navVideosLink');

  if (!vSection || !vGrid) return;

  const activeVideos = (videos && Array.isArray(videos)) ? videos.filter(v => v && v.trim() !== '') : [];

  if (activeVideos.length === 0) {
    vSection.classList.add('hidden');
    if (navLink) navLink.classList.add('hidden');
    return;
  }

  vSection.classList.remove('hidden');
  if (navLink) navLink.classList.remove('hidden');
  vGrid.innerHTML = '';

  activeVideos.forEach(videoUrl => {
    const embedUrl = getYouTubeEmbedUrl(videoUrl);
    if (!embedUrl) return;

    const vCard = document.createElement('div');
    vCard.className = 'video-card';
    vCard.innerHTML = `
      <div class="video-aspect-box">
        <iframe 
          src="${embedUrl}" 
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
          allowfullscreen>
        </iframe>
      </div>
    `;
    vGrid.appendChild(vCard);
  });
}

/**
 * Helper: Parse any YouTube / Shorts / Share links to clean Iframe Embed links
 */
function getYouTubeEmbedUrl(url) {
  if (!url) return '';
  const regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=|shorts\/)([^#\&\?]*).*/;
  const match = url.match(regExp);
  
  if (match && match[2].length === 11) {
    return `https://www.youtube.com/embed/${match[2]}`;
  }
  return url; // Fallback
}

/**
 * 5. Render Photo Gallery GRID (Base64 uploads)
 */
function renderGallery(gallery) {
  const grid = document.getElementById('galleryGrid');
  if (!grid) return;
  grid.innerHTML = '';

  const activePhotos = (gallery && gallery.length > 0) ? gallery : DEFAULT_GALLERY;

  activePhotos.forEach((src, index) => {
    const card = document.createElement('div');
    card.className = 'gallery-card';
    
    // Check if Base64, set appropriate source
    let imgSource = src;
    card.innerHTML = `
      <img src="${imgSource}" alt="Muscles Up Gym Facility Shot #${index + 1}" loading="lazy">
    `;
    grid.appendChild(card);
  });
}

/**
 * 6. Set Gym Contact Details
 */
function renderContactDetails(contact) {
  const addressNode = document.getElementById('contactAddress');
  const phoneNode = document.getElementById('contactPhone');
  const emailNode = document.getElementById('contactEmail');

  if (contact) {
    if (addressNode) addressNode.textContent = contact.address || 'Opposite High Court Lane, Sector 4, New Delhi';
    if (phoneNode) phoneNode.textContent = contact.phone || '+91 98765 43210';
    if (emailNode) emailNode.textContent = contact.email || 'support@musclesup.com';
  }
}

/**
 * Submit Lead callback inquiry form via AJAX REST post
 */
async function handleFormSubmit(e) {
  e.preventDefault();

  const nameInput = document.getElementById('formName');
  const phoneInput = document.getElementById('formPhone');
  const packageSelect = document.getElementById('formPackage');
  const messageInput = document.getElementById('formMessage');
  const btnSubmit = document.getElementById('btnSubmitForm');
  const statusBanner = document.getElementById('formStatus');

  if (!nameInput || !phoneInput || !packageSelect || !btnSubmit || !statusBanner) return;

  // Clear previous alerts
  statusBanner.className = 'form-status hidden';
  statusBanner.textContent = '';

  const nameVal = nameInput.value.trim();
  const phoneVal = phoneInput.value.trim().replace(/\D/g, ''); // Extract only digits
  const packageVal = packageSelect.value;
  const msgVal = messageInput ? messageInput.value.trim() : '';

  // 1. Client-side Validation Checks
  if (!nameVal) {
    showFormError(statusBanner, 'Please specify your full name.');
    return;
  }

  if (phoneVal.length !== 10) {
    showFormError(statusBanner, 'Please enter a valid 10-digit mobile number (e.g. 9876543210).');
    return;
  }

  if (!packageVal) {
    showFormError(statusBanner, 'Please select your desired Gym package.');
    return;
  }

  // 2. Lock Buttons & Show loading status
  btnSubmit.disabled = true;
  btnSubmit.textContent = 'SUBMITTING ENROLLMENT...';

  try {
    const postData = {
      name: nameVal,
      phone: phoneVal,
      packageName: packageVal,
      message: msgVal || undefined
    };

    const response = await fetch('/api/inquiries', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(postData)
    });

    const resJson = await response.json();

    if (!response.ok) {
      throw new Error(resJson.message || 'Server rejected lead request.');
    }

    // Success Sequence!
    statusBanner.className = 'form-status success';
    statusBanner.textContent = '⚡ Success! Your fitness callback inquiry is registered. Our coordinator will contact you in 1-2 hours.';
    showToastNotification('Callback inquiry registered successfully! 🏋️‍♂️', '✅');

    // Reset Form Elements
    nameInput.value = '';
    phoneInput.value = '';
    packageSelect.selectedIndex = 0;
    if (messageInput) messageInput.value = '';

  } catch (err) {
    console.error('🔴 Submission of inquiry failed:', err);
    showFormError(statusBanner, err.message || 'Connection failed. Please verify your internet/server address and try again.');
  } finally {
    btnSubmit.disabled = false;
    btnSubmit.textContent = 'SUBMIT FORM NOW ⚡';
  }
}

/**
 * Show error inline in form
 */
function showFormError(banner, message) {
  banner.className = 'form-status error';
  banner.textContent = `⚠️ Error: ${message}`;
  banner.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}

/**
 * Show a sleek sliding feedback toast panel
 */
let toastTimeoutId = null;
function showToastNotification(message, icon = '⚡') {
  const toastNode = document.getElementById('toastNotification');
  const toastIcon = document.getElementById('toastIcon');
  const toastMsg = document.getElementById('toastMessage');

  if (!toastNode || !toastMsg) return;

  if (toastTimeoutId) {
    clearTimeout(toastTimeoutId);
  }

  if (toastIcon) toastIcon.textContent = icon;
  toastMsg.textContent = message;

  toastNode.classList.remove('hidden');

  // Fade out after 4 seconds
  toastTimeoutId = setTimeout(() => {
    toastNode.classList.add('hidden');
  }, 4000);
}
