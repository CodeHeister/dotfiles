function parallax() {
    document.querySelector(".bg").addEventListener("mousemove", e => {
        var pers = 5;
        var width = e.currentTarget.clientWidth;
        var height = e.currentTarget.clientHeight;
        var x = e.pageX;
        var y = e.pageY;
        e.currentTarget.style.backgroundPosition = `${50+(width/height*pers)*(x-width/2)/(width/2)}% ${50+(height/width*pers)*(y-height/2)/(height/2)}%`;
    });

    els = document.querySelectorAll(".spinable");
    for (var i = 0; i < els.length; i++) {
        els[i].addEventListener("mouseleave", e => {
            e.target.style.transform = "perspective(1000px) rotateX(0deg) rotateY(0deg) scale3d(1, 1, 1)";
        });

        els[i].addEventListener("mousemove", e => {
            var deg = 30;
            var height = e.currentTarget.clientHeight;
            var width = e.currentTarget.clientWidth;
            var y = e.offsetY;
            var x = e.offsetX;
            e.currentTarget.style.transform = `perspective(1000px) rotateX(${(y-height/2)/height*(-deg)}deg) rotateY(${(x-width/2)/width*deg}deg) scale3d(1.05, 1.05, 1.05)`;
        });
    }
}