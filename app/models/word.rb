class Word
      attr_accessor :spelling, :idf, :tweet_no, :cluster_index
      def initialize(spelling,idf,tweet_no,cluster_index)
	@spelling = spelling
	@idf = idf
	@tweet_no = tweet_no
	@cluster_index = cluster_index
      end
      
      def to_s
	return "#{@spelling} , #{@idf} , #{@tweet_no} , #{@cluster_index}"
      end
end