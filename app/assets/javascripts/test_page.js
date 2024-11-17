(function() {
    root = typeof exports !== "undefined" && exports !== null ? exports : this;
    document.addEventListener('DOMContentLoaded', () => {
      const options = document.querySelectorAll('.option,.option-dunno');
      options.forEach(option => {
        option.addEventListener('mouseenter', () => {
          options.forEach(option => {option.blur(); });
          option.focus(); // Automatically focus the button on hover
        });
      });
    });
    // options.forEach(option => {
    //   // Hover to expand
    //   option.addEventListener('mouseenter', () => {
    //     if (option.classList.contains('long')) {
    //       const fullText = option.querySelector('.full-text');
    //       if (fullText) fullText.style.display = 'block';
    //     }
    //   });
    //
    //   option.addEventListener('mouseleave', () => {
    //     const fullText = option.querySelector('.full-text');
    //     if (fullText) fullText.style.display = 'none';
    //   });

    //   // Keyboard focus to expand
    //   option.addEventListener('focus', () => {
    //     const fullText = option.querySelector('.full-text');
    //     if (fullText) fullText.style.display = 'block';
    //   });
    //
    //   option.addEventListener('blur', () => {
    //     const fullText = option.querySelector('.full-text');
    //     if (fullText) fullText.style.display = 'none';
    //   });
    // });
    //});
}).call(this);
