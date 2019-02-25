ARG GOLANG=1.11.5
FROM golang:${GOLANG}-alpine3.9 AS build

# Versions
ARG VIPS_VERSION=8.7.4
ARG IMAGINARY_VERSION=1.1.0


#
# Begin VIPS: set up a build environment for vips
#             intentionally limited in features (most common file formats)
#

RUN echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    echo "@edge-main http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    apk add -U build-base ca-certificates fftw-dev giflib-dev lcms2-dev libexif-dev \
        libimagequant-dev@testing libintl libjpeg-turbo-dev@edge-main libpng-dev \
        libwebp-dev orc-dev tiff-dev upx zlib-dev glib-dev expat-dev && \
    wget -O- https://github.com/libvips/libvips/releases/download/v${VIPS_VERSION}/vips-${VIPS_VERSION}.tar.gz | tar -xzC /tmp && \
    cd /tmp/vips-${VIPS_VERSION} && \
    CFLAGS="-g -O3" CXXFLAGS="-D_GLIBCXX_USE_CXX11_ABI=0 -g -O3" \
    ./configure \
        --prefix=/vips \
        --disable-debug \
        --disable-dependency-tracking \
        --disable-introspection \
        --disable-static \
        --without-gsf \
        --without-magick \
        --without-openslide \
        --without-pdfium \
        --enable-gtk-doc-html=no \
        --enable-gtk-doc=no \
        --enable-pyvips8=no && \
    make -s install-strip

#
# End VIPS
#

#
# Begin Imaginary: build imaginary on top of VIPS
#

ARG PKG_CONFIG_PATH="/vips/lib/pkgconfig:$PKG_CONFIG_PATH"

RUN mkdir -p ${GOPATH}/src && \
    apk add git && \
    wget -O- https://github.com/h2non/imaginary/archive/v${IMAGINARY_VERSION}.tar.gz | tar -xzC ${GOPATH}/src && \
    cd ${GOPATH}/src/imaginary-${IMAGINARY_VERSION} && \
    go get -u golang.org/x/net/context github.com/golang/dep/cmd/dep github.com/rs/cors \
        gopkg.in/h2non/filetype.v1 github.com/throttled/throttled && \
    dep ensure && \
    go build -ldflags="-s -w" -o $GOPATH/bin/imaginary
RUN upx --best -q $GOPATH/bin/imaginary

#
# End Imaginary
#

#
# Begin container: a minimal environment for hosting the resulting binary/libraries
#

FROM alpine:3.9

ARG VIPS_VERSION=8.7.4
ARG IMAGINARY_VERSION=1.1.0
ARG GOLANG=1.11.5
ARG VCS_REF=unknown
ARG BUILD_DATE=unknown

ENV PORT 9000

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="imaginary-alpine" \
      org.label-schema.description="A slimmed-down version of Imaginary built on Alpine" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/jbergstroem/imaginary-alpine" \
      org.label-schema.schema-version="1.0.0-rc.1" \
      org.label-schema.license="Apache-2.0" \
      vips_version=$VIPS_VERSION \
      imaginary_version=$IMAGINARY_VERSION \
      golang_version=$GOLANG


COPY --from=build /vips/lib/ /usr/local/lib
COPY --from=build /go/bin/imaginary /usr/bin/imaginary
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

RUN echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    echo "@edge-main http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    apk add --no-cache fftw giflib lcms2 libexif libimagequant@testing libintl libjpeg-turbo@edge-main \
        libpng libwebp orc tiff glib expat && \
    rm -rf /usr/share/gtk-doc

EXPOSE $PORT

ENTRYPOINT ["/usr/bin/imaginary"]
