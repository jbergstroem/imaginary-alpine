# Imaginary, alpine edition

Imaginary is an excellent piece of software for working with images over http.

Quoting the author:

> Fast, simple, scalable HTTP microservice for high-level image processing
> with first-class Docker support.

This container seeks to find a compromise between size, functionality and stability.

## Supported formats

Note: I intend to add a e2e test suite to verify that these formats are supported.

-   jp(e)g
-   gif
-   png
-   webp
-   tiff

Also, these libraries:

-   ogre: fast math
-   cms2: ICC color management
-   exif: image metadata
-   fftw3: fourier transforms

## Container size

| Name                         | Version | Compressed size |
| :--------------------------- | :------ | :-------------- |
| h2non/imaginary              | 1.1.0   | 93mb            |
| jbergstroem/imaginary-alpine | 1.1.0   | ?               |

We achieve a smaller container size for a few reasons:

1. We use alpine linux instead of debian/ubuntu as base
2. We don't support as many file formats as upstream does
3. We intentionally skip the Imagemagick wrapper for size, performance and security reasons

## Important considerations

Since we are using Alpine as a base image, there are differences in libc (musl vs glibc). The main drawback is stack depth which may or may not affect you based on how complicated transforms you do.
