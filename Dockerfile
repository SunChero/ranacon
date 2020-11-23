FROM centos:7
RUN echo #reruired by root and build
RUN yum install -y libXcomposite libXcursor libXi libXtst libXrandr alsa-lib mesa-libEGL libXdamage mesa-libGL libXScrnSaver  texlive-* gcc-fortran  tcl tk readline-devel libX11-devel libXt-devel bzip2-devel xz-devel pcre-devel gsl-devel  glpk-devel gmp-devel mysql-devel mysql qt-mysql curl libcurl-devel compat-openssl10 texinfo which wget

RUN echo #mkdir source
RUN mkdir /app && mkdir /app/source
RUN echo #download intel_mkl

RUN cd /app/source && curl https://registrationcenter-download.intel.com/akdlm/irc_nas/tec/16917/l_mkl_2020.4.304.tgz -o l_mkl_2020.4.304.tgz && tar -xvf l_mkl_2020.4.304.tgz && cd l_mkl_2020.4.304 && ./install.sh --cli-mode -s --accept_eula --components="ALL" --install_dir=/app/source/intel --PSET_MODE=install
RUN echo install development tools
RUN yum groupinstall -y "Development Tools"
RUN echo #download R
RUN cd /app/source && curl -sfL https://cran.rstudio.com/src/base/R-4/R-4.0.3.tar.gz | tar -xvzf - && cd R-4.0.3 && source /app/source/intel/compilers_and_libraries/linux/mkl/bin/mklvars.sh intel64 &&  MKL="-Wl,--no-as-needed -lmkl_gf_lp64 -Wl,--start-group -lmkl_gnu_thread  -lmkl_core  -Wl,--end-group -fopenmp  -ldl -lpthread -lm" ./configure --with-blas="$MKL" --with-lapack --with-pcre1 --enable-R-shlib --enable-BLAS-shlib  --enable-openmp --with-pic --with-x --with-cairo  --with-readline --enable-memory-profiling --prefix=/app/r && make && make install

RUN echo #download Anaconda
RUN cd /app/source &&curl https://repo.anaconda.com/archive/Anaconda3-2020.11-Linux-x86_64.sh  -o install-anaconda.sh && chmod +x install-anaconda.sh && ./install-anaconda.sh -b -p /app/anaconda

RUN echo #setup conda env
RUN source /app/anaconda/bin/activate && conda create -n conda37 python=3.7 anaconda && conda activate conda37 && conda install -c fwaters pycharm

RUN echo #install R Studio
RUN cd /app/source && curl -sfL https://download1.rstudio.org/desktop/centos7/x86_64/rstudio-1.3.1093-x86_64-fedora.tar.gz | tar -xvzf -

RUN echo #install oracle java

RUN cd /app/source && wget --no-check-certificate -c --header "Cookie: oraclelicense=accept-securebackup-cookie" https://download.oracle.com/otn-pub/java/jdk/15.0.1+9/51f4f36ad4ef43e39d0dfdbaf6549e32/jdk-15.0.1_linux-x64_bin.rpm &&  rpm -ivh --prefix=/app/java jdk-15.0.1_linux-x64_bin.rpm

RUN cd /app
ADD ./patch.sh /app
RUN chmod +x /app/patch.sh

#cleanup
RUN cd /app/source
RUN rm -fr l_mkl_2020.4.304 l_mkl_2020.4.304 Anaconda3-2020.11-Linux-x86_64.sh  R-4.0.3/
RUN rm -fr l_mkl_2020.4.304.tgz
RUN rm -fr jdk-15.0.1_linux-x64_bin.rpm

#which binary needed for building on docker
RUN cd /
RUN tar -czvf app.tar.gz /app


FROM alpine:latest
COPY  --from=0 /app.tar.gz /

CMD /bin/bash
