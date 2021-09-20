# Docker file for MWA Pulsar Group
# Built to provide tempo2 tool
# contains python, libpng, hdf5, and a few
# other packages to 

FROM ubuntu:18.04

# Install dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get --no-install-recommends -y install \
    build-essential \
    autoconf \
    autotools-dev \
    automake \
    autogen \
    libtool \
    pkg-config \ 
    cmake \
    csh \
    g++ \
    gcc \
    gfortran \
    wget \
    git \
    expect \	
    libcfitsio-dev \
    hwloc \
    python \
    python-dev \
    python-pip \
    libfftw3-3 \
    libfftw3-bin \
    libfftw3-dev \
    libfftw3-single3 \
    libx11-dev \
    libpcre3 \
    libpcre3-dev \
    libpng-dev \ 
    libpnglite-dev \   
    #libhdf5-10 \
    #libhdf5-cpp-11 \
    libhdf5-dev \
    libhdf5-serial-dev \
    libxml2 \
    libxml2-dev \
    libltdl-dev \
    gsl-bin \
    libgsl-dev \
    openssh-server \
    xorg \
    bc \
    xauth && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get -y clean && \
    pip install pip -U && \
    pip install setuptools -U && \
    pip install numpy -U && \
    pip install scipy -U && \
    pip install matplotlib -U

# Create psr user which will be used to run commands with reduced privileges.
RUN adduser --disabled-password --gecos 'unprivileged user' psr && \
    echo "psr:psr" | chpasswd && \
    mkdir -p /home/psr/.ssh && \
    chown -R psr:psr /home/psr/.ssh
USER psr

# Define home, psrhome, OSTYPE and create the directory
ENV HOME /home/psr
ENV PSRHOME $HOME/software
ENV OSTYPE linux
RUN mkdir -p $PSRHOME
WORKDIR $PSRHOME

# setup environment variables 

# setup pgplot environment 
ENV PGPLOT_DIR $PSRHOME/pgplot/install/
ENV PGPLOT_FONT $PGPLOT_DIR/grfont.dat
ENV PGPLOT_INCLUDES $PGPLOT_DIR/include/
ENV PGPLOT_BACKGROUND white
ENV PGPLOT_FOREGROUND black
ENV PGPLOT_DEV /xs
ENV PATH $PATH:$PGPLOT_DIR/bin
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$PGPLOT_DIR/lib
ENV C_INCLUDE_PATH $C_INCLUDE_PATH:$PGPLOT_DIR/include
# set swig environment 
ENV SWIG_DIR $PSRHOME/swig 
ENV SWIG_PATH $SWIG_DIR/bin
ENV PATH=$SWIG_PATH:$PATH
ENV SWIG_EXECUTABLE $SWIG_DIR/bin/swig
ENV SWIG $SWIG_EXECUTABLE
# set calceph environment 
ENV CALCEPH $PSRHOME/calceph-3.4.5
ENV PATH $PATH:$CALCEPH/install/bin
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$CALCEPH/install/lib
ENV C_INCLUDE_PATH $C_INCLUDE_PATH:$CALCEPH/install/include
# set DAL environment 
ENV DAL $PSRHOME/DAL
ENV PATH $PATH:$DAL/install/bin
ENV C_INCLUDE_PATH $C_INCLUDE_PATH:$DAL/install/include
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$DAL/install/lib
# set Psrcat environment
ENV PSRCAT_FILE $PSRHOME/psrcat_tar/psrcat.db
ENV PATH $PATH:$PSRHOME/psrcat_tar
# set psrxml environment 
ENV PSRXML $PSRHOME/psrxml
ENV PATH $PATH:$PSRXML/install/bin
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$PSRXML/install/lib
ENV C_INCLUDE_PATH $C_INCLUDE_PATH:$PSRXML/install/include

# now build some packes from source
# first get all repos then 
# 1) build pgplot 
# 2) build swig
# 3) build calceph
# 4) build dal
# 5) build psrcat
# 6) build psrxml
# 7) biuld tempo2
RUN wget ftp://ftp.astro.caltech.edu/pub/pgplot/pgplot522.tar.gz && tar xf pgplot522.tar.gz -C $PSRHOME && rm pgplot522.tar.gz && \
  wget http://www.atnf.csiro.au/people/pulsar/psrcat/downloads/psrcat_pkg.tar.gz && tar -xvf psrcat_pkg.tar.gz -C $PSRHOME && rm psrcat_pkg.tar.gz && \
  wget https://www.imcce.fr/content/medias/recherche/equipes/asd/calceph/calceph-3.4.5.tar.gz && tar -xvf calceph-3.4.5.tar.gz -C $PSRHOME && rm calceph-3.4.5.tar.gz && \
  wget https://sourceforge.net/projects/swig/files/swig/swig-4.0.2/swig-4.0.2.tar.gz && tar -xvf swig-4.0.2.tar.gz -C $PSRHOME && rm swig-4.0.2.tar.gz && \
  git clone https://bitbucket.org/psrsoft/tempo2.git && \
  git clone git://git.code.sf.net/p/dspsr/code dspsr && \
  git clone git://git.code.sf.net/p/psrchive/code psrchive && \
  git clone https://github.com/SixByNine/psrxml.git && \
  git clone https://github.com/nextgen-astrodata/DAL.git && \
  git clone git://git.code.sf.net/p/psrdada/code psrdada && \
  # now build pgplot 
  cd pgplot && \
  # select drivers 
  sed -i 's/! CGDRIV/CGDRIV/' drivers.list && \
  sed -i 's/! LXDRIV/LXDRIV/' drivers.list && \
  sed -i 's/! PNDRIV/PNDRIV/' drivers.list && \
  sed -i 's/! GIDRIV/GIDRV/' drivers.list && \
  sed -i 's/! PSDRIV/PSDRIV/' drivers.list && \
  sed -i 's/! TTDRIV 5/TTDRIV 5/' drivers.list && \
  sed -i 's/! XWDRIV/XWDRIV/1' drivers.list && \
  sed -i 's/! XSDRIV/XSDRIV/1' drivers.list && \
  # apply patch 
  sed -i 's/if (setjmp(png_ptr->jmpbuf))/if (setjmp(png_jmpbuf(png_ptr)))/' drivers/pndriv.c && \
  # generate make file and make the package 
  ./makemake . linux g77_gcc && \
  sed -i 's=pndriv.o : ./png.h ./pngconf.h ./zlib.h ./zconf.h=#pndriv.o : ./png.h ./pngconf.h ./zlib.h ./zconf.h=' makefile && \
  make FCOMPL=gfortran SHARED_LIB_LIBS="-lpng -lz -lX11" all cpg && \
  # and then install 
  mkdir -p $PGPLOT_DIR/lib && mkdir -p $PGPLOT_DIR/include/ && mkdir -p $PGPLOT_DIR/bin/ && \
  install -D -m644 libpgplot.a $PGPLOT_DIR/lib/libpgplot.a && \
  install -D -m755 libpgplot.so $PGPLOT_DIR/lib/libpgplot.so && \
  install -D -m644 grfont.dat  $PGPLOT_DIR/grfont.dat && \
  install -D -m644 rgb.txt $PGPLOT_DIR/rgb.txt && \
  install -D -m755 pgxwin_server $PGPLOT_DIR/bin/pgxwin_server && \
  install -D -m644 libcpgplot.a $PGPLOT_DIR/lib/libcpgplot.a && \
  install -D -m644 cpgplot.h $PGPLOT_DIR/include/cpgplot.h && \
  cp *demo* $PGPLOT_DIR/bin/ && \
  # swig 
  cd $PSRHOME/swig-4.0.2 && \
  ./configure --prefix=$SWIG_DIR && \
  make && \
  make install && \
  make clean && \
  # calceph 
  cd $CALCEPH && \
  ./configure --prefix=$CALCEPH/install --with-pic --enable-shared --enable-static --enable-fortran --enable-thread && \
  make && \
  make check && \
  make install && \
  make clean && \
  # dal 
  mkdir -p $DAL/build && cd $DAL/build && \
  cmake .. -DCMAKE_INSTALL_PREFIX=$DAL/install && \
  make -j $(nproc) && \
  make && \
  make install && \
  make clean && \
  rm -rf .git && \
  # psrcat 
  cd $PSRHOME/psrcat_tar && \
  /bin/bash makeit && \
  # psrxml 
  cd $PSRXML && \
  autoreconf --install --warnings=none && \
  ./configure --prefix=$PSRXML/install && \
  make && \
  make install && \
  make clean && \
  rm -rf .git 

# set tempo2 environment 
ENV TEMPO2_DIR $PSRHOME/tempo2/
ENV TEMPO2 $PSRHOME/tempo2/install/
ENV PATH $PATH:$TEMPO2/bin/
ENV C_INCLUDE_PATH $C_INCLUDE_PATH:$TEMPO2/include
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$TEMPO2/lib
# set pschive environment 
ENV PSRCHIVE_DIR $PSRHOME/psrchive
ENV PSRCHIVE $PSRHOME/psrchive/install
ENV PATH $PATH:$PSRCHIVE/bin
ENV C_INCLUDE_PATH $C_INCLUDE_PATH:$PSRCHIVE/include
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$PSRCHIVE/lib
ENV PYTHONPATH $PSRCHIVE/lib/python2.7/site-packages

# tempo2  
RUN cd $TEMPO2_DIR && \
  ./bootstrap && \
  cp -r T2runtime/ $TEMPO2/ && \
  ./configure --prefix=$TEMPO2 --with-x --x-libraries=/usr/lib/x86_64-linux-gnu --with-fftw3-dir=/usr/ --with-calceph=$CALCEPH/install/lib \
  --enable-shared --enable-static --with-pic \
  CPPFLAGS="-I"$CALCEPH"/install/include -L"$CALCEPH"/install/lib/ -I"$PGPLOT_DIR"/include/ -L"$PGPLOT_DIR"/lib/" \
  CXXFLAGS="-I"$CALCEPH"/install/include -L"$CALCEPH"/install/lib/ -I"$PGPLOT_DIR"/include/ -L"$PGPLOT_DIR"/lib/" && \
  make -j && \
  make -j plugins && \
  make install && \
  make plugins-install && \
  rm -rf .git && \
  make clean && make plugins-clean 

# psrchive (which requires tempo2 to be built) 
RUN cd $PSRCHIVE_DIR && \
  ./bootstrap && \
  ./configure --prefix=$PSRCHIVE --x-libraries=/usr/lib/x86_64-linux-gnu --with-psrxml-dir=$PSRXML/install --enable-shared --enable-static F77=gfortran \
  CPPFLAGS="-I"$CALCEPH"/install/include -L"$CALCEPH"/install/lib/ -I"$PGPLOT_DIR"/include/ -L"$PGPLOT_DIR"/lib/" \
  CXXFLAGS="-I"$CALCEPH"/install/include -L"$CALCEPH"/install/lib/ -I"$PGPLOT_DIR"/include/ -L"$PGPLOT_DIR"/lib/" \
  LDFLAGS="-L"$PSRXML"/install/lib -L"$CALCEPH"/install/lib/  -L"$PGPLOT_DIR"/lib/ " LIBS="-lpsrxml -lxml2" && \  
  make -j && \
  make install && \
  rm -rf .git && \ 
  make clean && \
  cd $HOME && \
  echo "Predictor::default = tempo2" >> $HOME/.psrchive.cfg && \
  echo "Predictor::policy = default" >> $HOME/.psrchive.cfg

# finally update /etc/bash.bashrc and add simple command whoamI
USER root
RUN echo "echo \"Welcome to the tempo2/psrchive MWA Pulsar container\" " >> /etc/bash.bashrc && \
  echo "echo \"Try running tempo2 \" " >> /etc/bash.bashrc && \
  echo "echo \"============ \" " >> /etc/bash.bashrc && \
  echo "echo \"If you encounter issues running tempo2 container, please verify that you are bind mounting your .Xauthority file  \" " >> /etc/bash.bashrc && \
  echo "echo \"For example when running singularity: singularity -B \$HOME/.Xauthority your_container.sif pgdemo1  \" " >> /etc/bash.bashrc && \
  # add a command whoamI to container
  echo "#!/bin/bash" >> /usr/bin/whoamI && \
  echo "echo \"Welcome to the tempo2/psrchive MWA Pulsar container\" " >> /usr/bin/whoamI && \
  echo "echo \"Try running tempo2 \" " >> /usr/bin/whoamI && \
  echo "echo \"============ \" " >> /usr/bin/whoamI && \
  echo "echo \"If you encounter issues running tempo2 container, please verify that you are bind mounting your .Xauthority file  \" " >> /usr/bin/whoamI && \
  echo "echo \"For example when running singularity: singularity -B \$HOME/.Xauthority your_container.sif pgdemo1  \" " >> /usr/bin/whoamI && \
  chmod a+rx /usr/bin/whoamI  

  
WORKDIR $HOME
USER root
